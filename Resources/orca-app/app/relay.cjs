'use strict';

// Lets the terminal's `orca-app cli` run the orca CLI against the runtime this shell
// started. The orca CLI reaches a local runtime only through a Unix socket in the
// runtime's temp directory, which lives in the app sandbox, and the other way in (a
// pairing code over the WebSocket) needs the runtime to listen on the network, which
// it is not allowed to do here. The shell can run the CLI itself (same sandbox, same
// runtime), so it serves a small loopback relay: the terminal posts the arguments, the
// shell runs `orca <args>` with its own environment and returns what the command
// printed. The token is kept in ~/.config/orca-app/app-runtime/relay.json, which only
// exists while the runtime does.
//
// Nothing here needs Electron, so it is unit tested on its own.
const childProcess = require('node:child_process');
const crypto = require('node:crypto');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');

const MAX_BODY = 1024 * 1024;
const MAX_OUTPUT = 8 * 1024 * 1024;
const DEFAULT_TIMEOUT_MS = 60_000;
const MAX_TIMEOUT_MS = 300_000;
const MAX_ARGS = 200;
const MAX_ARG_LENGTH = 64 * 1024;
// Commands that would start another runtime or another app instead of talking to this one.
const DENIED = new Set(['serve', 'open']);

function relayFile(home) {
  return path.join(home, '.config', 'orca-app', 'app-runtime', 'relay.json');
}

function sameToken(given, expected) {
  const a = Buffer.from(String(given));
  const b = Buffer.from(expected);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

function reply(response, status, body) {
  const text = JSON.stringify(body);
  response.writeHead(status, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(text) });
  response.end(text);
}

// The request body when it is a valid run request, else a message.
function parseRun(text) {
  let body;
  try {
    body = JSON.parse(text);
  } catch {
    return { error: 'the body is not JSON' };
  }
  if (!body || typeof body !== 'object') return { error: 'the body must be an object' };
  const { args, cwd, timeoutMs } = body;
  if (!Array.isArray(args) || args.length === 0 || args.length > MAX_ARGS
    || args.some((arg) => typeof arg !== 'string' || arg.length > MAX_ARG_LENGTH || arg.includes('\0'))) {
    return { error: 'args must be a non-empty array of strings' };
  }
  if (DENIED.has(args[0])) return { error: `orca ${args[0]} is not available through the app` };
  if (cwd !== undefined && (typeof cwd !== 'string' || !path.isAbsolute(cwd))) return { error: 'cwd must be an absolute path' };
  if (timeoutMs !== undefined && (!Number.isInteger(timeoutMs) || timeoutMs < 1000 || timeoutMs > MAX_TIMEOUT_MS)) {
    return { error: `timeoutMs must be between 1000 and ${MAX_TIMEOUT_MS}` };
  }
  return { args, cwd, timeoutMs: timeoutMs || DEFAULT_TIMEOUT_MS };
}

// options: { orca, env, home, execFile (for tests) }
// Resolves to { port, token, stop() }; the relay listens on 127.0.0.1 only.
function startRelay({ orca, env, home, execFile = childProcess.execFile }) {
  const token = crypto.randomBytes(24).toString('hex');
  const server = http.createServer((request, response) => {
    if (!sameToken((request.headers.authorization || '').replace(/^Bearer /, ''), token)) {
      return reply(response, 401, { error: 'unauthorized' });
    }
    if (request.url === '/health' && request.method === 'GET') return reply(response, 200, { ok: true });
    if (request.url !== '/run') return reply(response, 404, { error: 'not found' });
    if (request.method !== 'POST') return reply(response, 405, { error: 'use POST' });
    if (!/^application\/json\b/.test(request.headers['content-type'] || '')) {
      return reply(response, 415, { error: 'send application/json' });
    }
    let size = 0;
    const chunks = [];
    let rejected = false;
    request.on('data', (chunk) => {
      size += chunk.length;
      if (size > MAX_BODY && !rejected) {
        rejected = true;
        reply(response, 413, { error: 'the request is too large' });
        request.destroy();
      } else if (!rejected) {
        chunks.push(chunk);
      }
    });
    request.on('end', () => {
      if (rejected) return;
      const run = parseRun(Buffer.concat(chunks).toString('utf8'));
      if (run.error) return reply(response, 400, { error: run.error });
      let cwd = home;
      if (run.cwd) {
        try {
          if (fs.statSync(run.cwd).isDirectory()) cwd = run.cwd;
        } catch {
          // The app cannot see that folder: run from the home folder instead.
        }
      }
      execFile(orca, run.args, {
        cwd, env, timeout: run.timeoutMs, maxBuffer: MAX_OUTPUT, killSignal: 'SIGKILL', encoding: 'utf8',
      }, (error, stdout, stderr) => {
        const timedOut = Boolean(error && error.killed);
        const code = error ? (typeof error.code === 'number' ? error.code : 1) : 0;
        reply(response, 200, {
          code, signal: error && error.signal ? error.signal : null, timedOut, stdout: stdout || '', stderr: stderr || '',
          spawnError: error && typeof error.code === 'string' ? error.code : null,
        });
      });
    });
  });
  return new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', () => {
      resolve({ port: server.address().port, token, stop: () => { server.close(); server.closeAllConnections?.(); } });
    });
  });
}

// What the terminal reads: where the relay is, its token, and whose process serves it.
function publish(home, { port, token, pid, runtimeId }, fileSystem = fs) {
  const file = relayFile(home);
  try {
    fileSystem.mkdirSync(path.dirname(file), { recursive: true });
    fileSystem.writeFileSync(file, JSON.stringify({ version: 1, port, token, pid, runtimeId }) + '\n', { mode: 0o600 });
    return true;
  } catch {
    return false;
  }
}

// Remove the registration, but only the one this process wrote.
function unpublish(home, pid, fileSystem = fs) {
  const file = relayFile(home);
  try {
    if (JSON.parse(fileSystem.readFileSync(file, 'utf8')).pid === pid) fileSystem.unlinkSync(file);
    return true;
  } catch {
    return false;
  }
}

function readRelay(home, fileSystem = fs) {
  try {
    const data = JSON.parse(fileSystem.readFileSync(relayFile(home), 'utf8'));
    if (data.version !== 1 || !Number.isInteger(data.port) || data.port < 1 || data.port > 65535
      || typeof data.token !== 'string' || !/^[0-9a-f]{32,}$/.test(data.token)) return null;
    return { port: data.port, token: data.token, pid: Number.isInteger(data.pid) ? data.pid : null, runtimeId: data.runtimeId || null };
  } catch {
    return null;
  }
}

module.exports = {
  DENIED, MAX_BODY, MAX_TIMEOUT_MS, parseRun, publish, readRelay, relayFile, startRelay, unpublish,
};
