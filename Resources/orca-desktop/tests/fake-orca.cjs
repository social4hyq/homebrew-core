'use strict';

// A stand-in for the orca CLI/runtime, for the shell and script tests.
//   fake-orca.cjs serve --port N --json     serves /web-index.html on N, prints the ready record,
//                                           writes orca-runtime.json into ORCA_USER_DATA
//   fake-orca.cjs terminal list --json      prints how many terminals there are (FAKE_TERMINALS)
//   fake-orca.cjs status                    prints which profile it was pointed at
// FAKE_INSTALLATION decides the host the link is for; FAKE_ORCA_LOG gets one JSON line per start.
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');

const args = process.argv.slice(2);
if (process.env.FAKE_ORCA_LOG) fs.appendFileSync(process.env.FAKE_ORCA_LOG, JSON.stringify({ args, profile: process.env.ORCA_USER_DATA_PATH || null }) + '\n');

function pairingLink(port, installation) {
  const payload = { v: 2, endpoint: `ws://127.0.0.1:${port}`, deviceToken: 'tok', publicKeyB64: 'key-' + installation,
    scope: 'runtime', hostDescriptor: { installationId: installation } };
  const code = Buffer.from(JSON.stringify(payload)).toString('base64url');
  return `http://127.0.0.1:${port}/web-index.html#pairing=${encodeURIComponent('orca://pair?code=' + code)}`;
}

if (args[0] === 'serve') {
  const port = Number(args[args.indexOf('--port') + 1]);
  const runtimeId = process.env.FAKE_RUNTIME_ID || 'runtime-own-1';
  const installation = process.env.FAKE_INSTALLATION || 'own-host';
  const server = http.createServer((request, response) => {
    response.statusCode = request.url.startsWith('/web-index.html') ? 200 : 404;
    response.end(response.statusCode === 200 ? '<html></html>' : '');
  });
  server.listen(port, '127.0.0.1', () => {
    const root = process.env.ORCA_USER_DATA;
    if (root && !process.env.FAKE_NO_RUNTIME_JSON) {
      fs.mkdirSync(root, { recursive: true });
      fs.writeFileSync(path.join(root, 'orca-runtime.json'), JSON.stringify({
        runtimeId: process.env.FAKE_RUNTIME_JSON_ID || runtimeId, pid: process.pid, transports: [{ kind: 'ws', port }], authToken: 'secret-token', startedAt: 1,
      }));
    }
    process.stdout.write(JSON.stringify({
      type: 'orca_server_ready', schemaVersion: 1, runtimeId, endpoint: `ws://127.0.0.1:${port}`,
      pairing: { available: true, webClientUrl: pairingLink(port, installation) },
    }) + '\n');
  });
  process.on('SIGTERM', () => process.exit(0));
} else if (args[0] === 'terminal' && args[1] === 'list') {
  if (process.env.FAKE_TERMINALS === 'fail') process.exit(1);
  process.stdout.write(JSON.stringify({ ok: true, result: { terminals: [], totalCount: Number(process.env.FAKE_TERMINALS || 0) } }) + '\n');
} else if (args[0] === 'cwd') {
  process.stdout.write(process.cwd() + '\n');
} else if (args[0] === 'exit') {
  process.stderr.write('exiting with ' + args[1] + '\n');
  process.exit(Number(args[1]));
} else if (args[0] === 'sleep') {
  setTimeout(() => process.stdout.write('slept\n'), Number(args[1]));
} else if (args[0] === 'big') {
  process.stdout.write('x'.repeat(Number(args[1])));
} else {
  process.stdout.write('fake-orca ' + args.join(' ') + ' profile=' + (process.env.ORCA_USER_DATA_PATH || '') + '\n');
}
module.exports = { pairingLink };
