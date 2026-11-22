'use strict';

// Stands in for `codex app-server` (JSON-RPC lines on stdin/stdout) when the
// terminal runs a shared server (see owl-share.cjs). Runs under the host Node:
//   node owl-codex-bridge.cjs --endpoint server.json --codex <codex> -- <codex args>
//
// It attaches to the server's loopback WebSocket with the capability token and
// copies one JSON message per line each way. When the server cannot be reached
// or refuses the token it runs `<codex> <args>` itself, so the app behaves as
// before. If the server goes away later the bridge exits, and the app starts
// it again like any crashed app-server.
const fs = require('node:fs');
const childProcess = require('node:child_process');

const CONNECT_TIMEOUT_MS = 2000;

function say(message) {
  try { process.stderr.write('[owl-share] ' + message + '\n'); } catch {}
}

function parse(argv) {
  const split = argv.indexOf('--');
  const own = split < 0 ? argv : argv.slice(0, split);
  const rest = split < 0 ? [] : argv.slice(split + 1);
  const value = (flag) => {
    const at = own.indexOf(flag);
    return at >= 0 ? own[at + 1] : undefined;
  };
  return { endpoint: value('--endpoint'), codex: value('--codex'), rest };
}

function runOwn(codex, args, reason) {
  say(reason + '; starting codex itself');
  const child = childProcess.spawn(codex, args, { stdio: 'inherit', env: process.env });
  for (const signal of ['SIGTERM', 'SIGINT', 'SIGHUP']) {
    process.on(signal, () => { try { child.kill(signal); } catch {} });
  }
  child.on('error', (error) => { say('could not start codex: ' + error.message); process.exit(127); });
  child.on('exit', (code, signal) => process.exit(code === null ? (signal ? 128 : 1) : code));
}

function connect(url, token) {
  return new Promise((resolve, reject) => {
    if (typeof WebSocket === 'undefined') return reject(new Error('this Node has no WebSocket'));
    let socket;
    try {
      socket = new WebSocket(url, { headers: { Authorization: 'Bearer ' + token } });
    } catch (error) {
      return reject(error);
    }
    const timer = setTimeout(() => { try { socket.close(); } catch {} reject(new Error('timed out')); }, CONNECT_TIMEOUT_MS);
    socket.onopen = () => { clearTimeout(timer); socket.onerror = null; resolve(socket); };
    socket.onerror = () => { clearTimeout(timer); reject(new Error('connection refused')); };
    socket.onclose = () => { clearTimeout(timer); reject(new Error('connection closed')); };
  });
}

function pipe(socket) {
  let pending = '';
  socket.onmessage = (event) => {
    const text = typeof event.data === 'string' ? event.data : Buffer.from(event.data).toString('utf8');
    process.stdout.write(text.endsWith('\n') ? text : text + '\n');
  };
  socket.onclose = () => { say('the shared server closed the connection'); process.exit(1); };
  socket.onerror = () => { say('the shared server connection failed'); process.exit(1); };
  process.stdin.setEncoding('utf8');
  process.stdin.on('data', (chunk) => {
    pending += chunk;
    let at;
    while ((at = pending.indexOf('\n')) >= 0) {
      const line = pending.slice(0, at).trim();
      pending = pending.slice(at + 1);
      if (line) socket.send(line);
    }
  });
  process.stdin.on('end', () => {
    const last = pending.trim();
    if (last) socket.send(last);
    // The app is done with us: closing the connection is the normal end.
    socket.onclose = null;
    socket.onerror = null;
    try { socket.close(); } catch {}
    setTimeout(() => process.exit(0), 100);
  });
  process.stdin.resume();
}

async function main() {
  const { endpoint, codex, rest } = parse(process.argv.slice(2));
  if (!endpoint || !codex || rest.length === 0) {
    say('usage: owl-codex-bridge.cjs --endpoint FILE --codex CLI -- ARGS');
    process.exit(2);
  }
  // Hold stdin until it is decided who answers, so no request is lost.
  process.stdin.pause();
  let socket;
  try {
    const info = JSON.parse(fs.readFileSync(endpoint, 'utf8'));
    const token = fs.readFileSync(info.tokenFile, 'utf8').trim();
    socket = await connect('ws://127.0.0.1:' + info.port, token);
  } catch (error) {
    return runOwn(codex, rest, 'no usable shared server (' + error.message + ')');
  }
  say('attached to the shared server on port ' + new URL(socket.url).port);
  pipe(socket);
}

main();
