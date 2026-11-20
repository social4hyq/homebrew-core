'use strict';

// Runs under the host Node (not Electron).  Owns one pseudo terminal and talks
// to the HAP-side shim (owl-pty-shim.cjs) over stdin/stdout JSON lines:
//   in : {t:'spawn',file,args,cwd,env,cols,rows} {t:'write',d} {t:'resize',c,r} {t:'kill',s}
//   out: {t:'ready',pid} {t:'data',d} {t:'exit',code,signal} {t:'error',m}
// Closing stdin terminates the terminal.

const path = require('node:path');

function send(message) {
  try {
    process.stdout.write(JSON.stringify(message) + '\n');
  } catch (_) {
    // The parent is gone; stdin 'end' will clean up.
  }
}

let pty = null;
let term = null;

function load() {
  const dir = process.env.OWL_NODE_PTY_DIR;
  return require(dir ? path.resolve(dir) : 'node-pty');
}

function onMessage(msg) {
  switch (msg.t) {
    case 'spawn': {
      try {
        pty = load();
        term = pty.spawn(msg.file, msg.args || [], {
          name: 'xterm-256color',
          cols: msg.cols || 80,
          rows: msg.rows || 24,
          cwd: msg.cwd,
          env: msg.env,
        });
      } catch (error) {
        send({ t: 'error', m: String(error && error.message || error) });
        process.exit(2);
        return;
      }
      term.onData((d) => send({ t: 'data', d }));
      term.onExit(({ exitCode, signal }) => {
        send({ t: 'exit', code: exitCode, signal: signal || null });
        setImmediate(() => process.exit(0));
      });
      send({ t: 'ready', pid: term.pid });
      break;
    }
    case 'write':
      if (term) term.write(msg.d);
      break;
    case 'resize':
      if (term) {
        try { term.resize(msg.c, msg.r); } catch (error) { send({ t: 'error', m: 'resize: ' + error.message }); }
      }
      break;
    case 'kill':
      if (term) {
        try { term.kill(msg.s); } catch (_) {}
      }
      break;
    default:
      break;
  }
}

let buffer = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', (chunk) => {
  buffer += chunk;
  let index;
  while ((index = buffer.indexOf('\n')) >= 0) {
    const line = buffer.slice(0, index);
    buffer = buffer.slice(index + 1);
    if (!line) continue;
    try { onMessage(JSON.parse(line)); } catch (error) { send({ t: 'error', m: 'bad message: ' + error.message }); }
  }
});
process.stdin.on('end', () => {
  if (term) { try { term.kill('SIGKILL'); } catch (_) {} }
  process.exit(0);
});
