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
// Nothing here needs Electron, so the decisions are unit tested on their own.
const fs = require('node:fs');
const path = require('node:path');

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
  return { kind: 'link', url: ready.webClientUrl, runtimeId: ready.runtimeId, reason: 'pair' };
}

function readState(file) {
  try {
    const state = JSON.parse(fs.readFileSync(file, 'utf8'));
    const pick = (value) => (typeof value === 'string' && value.length > 0 ? value : null);
    return {
      lastPairedRuntimeId: pick(state && state.lastPairedRuntimeId),
      lastTriedRuntimeId: pick(state && state.lastTriedRuntimeId),
    };
  } catch {
    return { lastPairedRuntimeId: null, lastTriedRuntimeId: null };
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

module.exports = {
  HEAD_BYTES,
  TAIL_BYTES,
  chooseTarget,
  lastClientConnectedAt,
  parseReadyRecord,
  readHead,
  readState,
  readTail,
  writeState,
};
