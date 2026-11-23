'use strict';

// A stand-in for the magpie CLI, for the tests of `magpie-app web` and of the shell:
//   fake-magpie.cjs web --addr HOST:PORT --no-open   a page that signs in with MAGPIE_WEB_KEY
//   fake-magpie.cjs serve --web=127.0.0.1:0          what the shell starts itself
// Every start is appended to FAKE_MAGPIE_LOG as one JSON line.
const fs = require('node:fs');
const http = require('node:http');

const args = process.argv.slice(2);
if (process.env.FAKE_MAGPIE_LOG) fs.appendFileSync(process.env.FAKE_MAGPIE_LOG, JSON.stringify(args) + '\n');
const key = process.env.MAGPIE_WEB_KEY || '';

const server = http.createServer((request, response) => {
  const url = new URL(request.url, 'http://localhost');
  if (url.searchParams.get('k') === key && key) {
    response.writeHead(303, { location: '/', 'set-cookie': 'session=ok' });
  } else {
    response.writeHead(401);
  }
  response.end();
});

if (args[0] === 'web') {
  const [host, port] = args[args.indexOf('--addr') + 1].split(':');
  server.listen(Number(port), host, () => {
    process.stdout.write(`● magpie web on http://${host}:${port}/?k=${key}\n`);
  });
} else if (args[0] === 'serve') {
  const wanted = Number((args.find((arg) => arg.startsWith('--web=')) || '--web=127.0.0.1:0').split(':').pop());
  server.on('error', () => process.exit(1));
  server.listen(wanted, '127.0.0.1', () => {
    process.stdout.write(`magpie web on http://127.0.0.1:${server.address().port}/?k=${key}\n`);
  });
} else {
  process.stdout.write('fake-magpie ' + args.join(' ') + '\n');
  process.exit(0);
}
process.on('SIGTERM', () => process.exit(0));
