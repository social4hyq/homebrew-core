'use strict';

// Stands in for the host `codex` in tests. It answers only what the tests ask:
//   fake-codex.cjs app-server [...]                       JSON-RPC lines on stdio
//   fake-codex.cjs app-server --listen ws://127.0.0.1:PORT --ws-token-file FILE ...
//                                                          /readyz and a token-checked WebSocket
// Every request {id, method} is answered with {id, result: {server, method}}.
const crypto = require('node:crypto');
const fs = require('node:fs');
const http = require('node:http');

const args = process.argv.slice(2);
const value = (flag) => { const at = args.indexOf(flag); return at >= 0 ? args[at + 1] : undefined; };
const reply = (kind, line) => {
  let request;
  try { request = JSON.parse(line); } catch { return null; }
  if (request.id === undefined) return null;
  return JSON.stringify({ id: request.id, result: { server: kind, method: request.method } });
};

if (!args.includes('app-server')) {
  process.stdout.write('fake-codex ' + args.join(' ') + '\n');
  process.exit(0);
}

if (process.env.FAKE_CODEX_ARGS_FILE) fs.writeFileSync(process.env.FAKE_CODEX_ARGS_FILE, JSON.stringify(args));
const listen = value('--listen');
// A codex that cannot serve a WebSocket (tests of the fallback to a private server).
if (listen && process.env.FAKE_CODEX_NO_LISTEN) process.exit(1);
if (!listen) {
  let pending = '';
  process.stdin.setEncoding('utf8');
  process.stdin.on('data', (chunk) => {
    pending += chunk;
    let at;
    while ((at = pending.indexOf('\n')) >= 0) {
      const out = reply('own-stdio', pending.slice(0, at));
      pending = pending.slice(at + 1);
      if (out) process.stdout.write(out + '\n');
    }
  });
  process.stdin.on('end', () => process.exit(0));
} else {
  const port = Number(new URL(listen).port);
  const token = fs.readFileSync(value('--ws-token-file'), 'utf8').trim();
  const server = http.createServer((request, response) => {
    response.statusCode = request.url === '/readyz' || request.url === '/healthz' ? 200 : 400;
    response.end('ok');
  });
  const frame = (text) => {
    const body = Buffer.from(text);
    const head = body.length < 126 ? Buffer.from([0x81, body.length]) : Buffer.from([0x81, 126, body.length >> 8, body.length & 255]);
    return Buffer.concat([head, body]);
  };
  server.on('upgrade', (request, socket) => {
    if (request.headers.authorization !== 'Bearer ' + token) {
      socket.end('HTTP/1.1 401 Unauthorized\r\nConnection: close\r\n\r\n');
      return;
    }
    const accept = crypto.createHash('sha1')
      .update(request.headers['sec-websocket-key'] + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11').digest('base64');
    socket.write('HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n' +
      'Sec-WebSocket-Accept: ' + accept + '\r\n\r\n');
    let buffered = Buffer.alloc(0);
    socket.on('data', (chunk) => {
      buffered = Buffer.concat([buffered, chunk]);
      for (;;) {
        if (buffered.length < 2) return;
        const opcode = buffered[0] & 15;
        let length = buffered[1] & 127;
        let offset = 2;
        if (length === 126) { if (buffered.length < 4) return; length = buffered.readUInt16BE(2); offset = 4; }
        if (buffered.length < offset + 4 + length) return;
        const mask = buffered.subarray(offset, offset + 4);
        const payload = Buffer.from(buffered.subarray(offset + 4, offset + 4 + length));
        for (let i = 0; i < payload.length; i += 1) payload[i] ^= mask[i % 4];
        buffered = buffered.subarray(offset + 4 + length);
        if (opcode === 8) { socket.end(Buffer.from([0x88, 0])); return; }
        if (opcode === 1) {
          const out = reply('shared-ws', payload.toString('utf8'));
          if (out) socket.write(frame(out));
        }
      }
    });
    socket.on('error', () => {});
  });
  server.listen(port, '127.0.0.1');
}
