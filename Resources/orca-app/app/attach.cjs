'use strict';
// Choosing how the Orca shell reaches a runtime that is already serving.
//
// `orca-app serve` (run from a terminal) leaves the runtime's stdout in
// ~/.config/orca-app/server.ready.json: the first line is the ready record with
// the pairing link, later lines are the runtime's log. The shell reads that
// record instead of starting a second runtime. The link is single use, so the
// shell remembers which runtime it has already paired with (and which one it
// tried without a confirmed connection) and then opens the plain client, which
// reconnects with the identity the web client saved.
//
// Two more things live here. The web client keeps one "saved server" and asks the
// user to confirm whenever a link is for a different host (a terminal's runtime
// after the app's own, or back); hostIdOf and needsFreshSavedServer let the shell
// drop the saved server first, so the link connects without a question. And the
// terminal's orca CLI needs only the runtime's orca-runtime.json to drive a
// runtime whose data root it cannot see (the app's own lives in the app sandbox),
// so publishRuntimeProfile copies it to a directory under the host home.
//
// Nothing here needs Electron, so the decisions are unit tested on their own.
const fs = require('node:fs');
const path = require('node:path');

// localStorage key of the web client's saved server (web-runtime-environment).
const SAVED_SERVER_KEY = 'orca.web.runtimeEnvironment.v1';

// The ready record is the first line; the rest of the file keeps growing.
const HEAD_BYTES = 64 * 1024;
const TAIL_BYTES = 128 * 1024;

function readRange(file, position, length) {
  let fd;
  try {
    fd = fs.openSync(file, 'r');
    const buffer = Buffer.alloc(length);
    const read = fs.readSync(fd, buffer, 0, length, position);
    return buffer.toString('utf8', 0, read);
  } catch {
    return null;
  } finally {
    if (fd !== undefined) {
      try { fs.closeSync(fd); } catch {}
    }
  }
}

function readHead(file, bytes = HEAD_BYTES) {
  return readRange(file, 0, bytes);
}

function readTail(file, bytes = TAIL_BYTES) {
  let size;
  try {
    size = fs.statSync(file).size;
  } catch {
    return null;
  }
  const start = Math.max(0, size - bytes);
  return readRange(file, start, size - start);
}

function portOf(endpoint) {
  try {
    const port = Number(new URL(endpoint).port);
    return Number.isInteger(port) && port > 0 ? port : null;
  } catch {
    return null;
  }
}

// The first `orca_server_ready` record in `text`, reduced to what the shell
// uses, or null. Lines that are not JSON (log output) are skipped.
function parseReadyRecord(text) {
  if (typeof text !== 'string') return null;
  for (const line of text.split('\n')) {
    if (!line.includes('orca_server_ready')) continue;
    let record;
    try {
      record = JSON.parse(line);
    } catch {
      continue;
    }
    if (!record || record.type !== 'orca_server_ready') continue;
    const link = record.pairing && record.pairing.webClientUrl;
    if (typeof record.runtimeId !== 'string' || !record.runtimeId) continue;
    return {
      runtimeId: record.runtimeId,
      port: portOf(record.endpoint),
      webClientUrl: typeof link === 'string' && link.length > 0 ? link : null,
    };
  }
  return null;
}

// Timestamp of the last "client connected" line the runtime logged, or null.
// Log lines start with an ISO timestamp, so the values compare as strings.
function lastClientConnectedAt(text) {
  if (typeof text !== 'string') return null;
  let last = null;
  const pattern = /^(\d{4}-\d{2}-\d{2}T[0-9:.]+Z) \[runtime-rpc\] client connected/gm;
  for (let match = pattern.exec(text); match; match = pattern.exec(text)) last = match[1];
  return last;
}

// The pairing payload of a web client link: the fragment (or query) carries
// `pairing=orca://pair?code=<base64url JSON>`, or the code itself.
function pairingPayload(link) {
  let url;
  try {
    url = new URL(link);
  } catch {
    return null;
  }
  const params = new URLSearchParams(url.hash.replace(/^#/, '') || url.search);
  let raw = null;
  for (const key of ['pairing', 'pair', 'code', 'token']) {
    const value = params.get(key);
    if (value && value.trim()) { raw = value.trim(); break; }
  }
  if (!raw) return null;
  try {
    if (raw.toLowerCase().startsWith('orca://')) raw = new URL(raw).searchParams.get('code') || '';
    const json = JSON.parse(Buffer.from(raw.replace(/-/g, '+').replace(/_/g, '/'), 'base64').toString('utf8'));
    return json && typeof json === 'object' ? json : null;
  } catch {
    return null;
  }
}

// Which orca host a link is for: the installation id the runtime keeps in its data
// root (the web client's own "same host" test also goes by the host's keys), else
// its public key, else null when the link cannot be read.
function hostIdOf(link) {
  const payload = pairingPayload(link);
  if (!payload) return null;
  const installation = payload.hostDescriptor && payload.hostDescriptor.installationId;
  if (typeof installation === 'string' && installation) return 'installation:' + installation;
  if (typeof payload.publicKeyB64 === 'string' && payload.publicKeyB64) return 'key:' + payload.publicKeyB64;
  return null;
}

// True when opening `url` would make the web client ask to replace its saved
// server: the url carries a pairing link and the saved server belongs to another
// host (or to one this shell never recorded). Clearing the saved server first
// makes the client save the link's server and connect without asking.
function needsFreshSavedServer({ url, state }) {
  if (!pairingPayload(url)) return false;
  const known = state && state.pairedHostId;
  return !known || known !== hostIdOf(url);
}

// What to open for a runtime this shell did not start.
//   ready  parsed ready record or null
//   state  {lastPairedRuntimeId, lastTriedRuntimeId}
// Returns {kind: 'link' | 'plain', url, runtimeId, reason}.
function chooseTarget({ origin, ready, state }) {
  const plain = origin + '/web-index.html';
  const known = state || {};
  if (!ready || !ready.webClientUrl) return { kind: 'plain', url: plain, runtimeId: null, reason: 'no-ready-record' };
  if (ready.port !== portOf(origin)) return { kind: 'plain', url: plain, runtimeId: null, reason: 'other-port' };
  if (!ready.webClientUrl.startsWith(origin + '/')) {
    return { kind: 'plain', url: plain, runtimeId: null, reason: 'other-origin' };
  }
  if (known.lastPairedRuntimeId === ready.runtimeId) {
    return { kind: 'plain', url: plain, runtimeId: ready.runtimeId, reason: 'already-paired' };
  }
  // The link was opened for this runtime before but no connection followed: it
  // is probably spent or stale, so fall back to the saved identity.
  if (known.lastTriedRuntimeId === ready.runtimeId) {
    return { kind: 'plain', url: plain, runtimeId: ready.runtimeId, reason: 'link-not-confirmed' };
  }
  return { kind: 'link', url: ready.webClientUrl, runtimeId: ready.runtimeId, reason: 'pair', hostId: hostIdOf(ready.webClientUrl) };
}

function readState(file) {
  try {
    const state = JSON.parse(fs.readFileSync(file, 'utf8'));
    const pick = (value) => (typeof value === 'string' && value.length > 0 ? value : null);
    return {
      lastPairedRuntimeId: pick(state && state.lastPairedRuntimeId),
      lastTriedRuntimeId: pick(state && state.lastTriedRuntimeId),
      pairedHostId: pick(state && state.pairedHostId),
    };
  } catch {
    return { lastPairedRuntimeId: null, lastTriedRuntimeId: null, pairedHostId: null };
  }
}

function writeState(file, state) {
  try {
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, JSON.stringify(state) + '\n');
    return true;
  } catch {
    return false;
  }
}

// Where the terminal's CLI finds the runtime this shell started: a profile
// directory under the host home (the app's own data root is in its sandbox).
function profileDir(home) {
  return path.join(home, '.config', 'orca-app', 'app-runtime');
}

// Copy the runtime's orca-runtime.json (port and auth token) to the profile
// directory, only when it describes the runtime that just announced itself.
function publishRuntimeProfile({ dataRoot, home, runtimeId }) {
  try {
    const text = fs.readFileSync(path.join(dataRoot, 'orca-runtime.json'), 'utf8');
    const record = JSON.parse(text);
    if (!record || (runtimeId && record.runtimeId !== runtimeId)) return false;
    const dir = profileDir(home);
    fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(path.join(dir, 'orca-runtime.json'), text, { mode: 0o600 });
    return true;
  } catch {
    return false;
  }
}

// Remove the published profile, but only the one that is still this runtime's.
function unpublishRuntimeProfile({ home, runtimeId }) {
  const file = path.join(profileDir(home), 'orca-runtime.json');
  try {
    if (runtimeId && JSON.parse(fs.readFileSync(file, 'utf8')).runtimeId !== runtimeId) return false;
    fs.unlinkSync(file);
    return true;
  } catch {
    return false;
  }
}

module.exports = {
  HEAD_BYTES,
  SAVED_SERVER_KEY,
  TAIL_BYTES,
  chooseTarget,
  hostIdOf,
  lastClientConnectedAt,
  needsFreshSavedServer,
  parseReadyRecord,
  profileDir,
  publishRuntimeProfile,
  readHead,
  readState,
  readTail,
  unpublishRuntimeProfile,
  writeState,
};
