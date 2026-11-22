'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');

const { DEFAULT_PORT, ensureKey, keyFile, preferredPort, probe, readTarget, register, targetFile, unregister } = require('../app/shared-web.cjs');

const KEY = 'a'.repeat(64);

// `content` is web.json (an object is serialised), `key` the web-key file.
function homeWith(content, key = KEY) {
  const home = fs.mkdtempSync(path.join(os.tmpdir(), 'magpie-shared-'));
  if (content !== undefined) {
    fs.mkdirSync(path.dirname(targetFile(home)), { recursive: true });
    fs.writeFileSync(targetFile(home), typeof content === 'string' ? content : JSON.stringify(content));
    if (key !== null) fs.writeFileSync(keyFile(home), key + '\n');
  }
  return home;
}

test('the registration lives under the host home', () => {
  assert.equal(targetFile('/h'), '/h/.config/magpie-app/web.json');
  assert.equal(keyFile('/h'), '/h/.config/magpie-app/web-key');
});

test('readTarget returns the page link for a valid registration', () => {
  const home = homeWith({ version: 1, port: 3430 });
  const target = readTarget(home);
  assert.equal(target.url.href, `http://127.0.0.1:3430/?k=${KEY}`);
  assert.equal(target.url.origin, 'http://127.0.0.1:3430');
});

test('readTarget refuses a missing, malformed or unsafe registration', () => {
  assert.equal(readTarget(homeWith()), undefined);
  assert.equal(readTarget(homeWith('not json')), undefined);
  assert.equal(readTarget(homeWith({ port: 3430 }, null)), undefined, 'no key file');
  assert.equal(readTarget(homeWith({ port: 3430 }, 'short')), undefined);
  assert.equal(readTarget(homeWith({ port: 3430 }, 'x/../../../y'.padEnd(20, 'z'))), undefined);
  assert.equal(readTarget(homeWith({ port: 3430 }, KEY.slice(0, 20) + '&evil=1' + KEY.slice(0, 20))), undefined);
  assert.equal(readTarget(homeWith({ port: 0 })), undefined);
  assert.equal(readTarget(homeWith({ port: 70000 })), undefined);
  assert.equal(readTarget(homeWith({ port: 'evil.example:80#' })), undefined);
  assert.equal(readTarget(''), undefined);
  assert.equal(readTarget(undefined), undefined);
});

test('a registration never points anywhere but loopback', () => {
  const home = homeWith({ port: 3430, host: 'evil.example', url: 'http://evil.example/' });
  assert.equal(readTarget(home).url.hostname, '127.0.0.1');
});

function listen(handler) {
  return new Promise((resolve) => {
    const server = http.createServer(handler);
    server.listen(0, '127.0.0.1', () => resolve(server));
  });
}

test('probe is true for a page that signs the key in and false for 401', async (t) => {
  const good = await listen((request, response) => { response.writeHead(303, { location: '/' }); response.end(); });
  const bad = await listen((request, response) => { response.writeHead(401); response.end(); });
  t.after(() => { good.close(); bad.close(); });
  const at = (server) => ({ url: new URL(`http://127.0.0.1:${server.address().port}/?k=${KEY}`) });
  assert.equal(await probe(at(good)), true);
  assert.equal(await probe(at(bad)), false);
});

test('probe is false when nothing listens and when the server does not answer', async (t) => {
  const closed = await listen(() => {});
  const port = closed.address().port;
  const silent = await listen(() => {});
  t.after(() => { silent.closeAllConnections(); silent.close(); });
  closed.close();
  assert.equal(await probe({ url: new URL(`http://127.0.0.1:${port}/?k=${KEY}`) }), false);
  const started = Date.now();
  assert.equal(await probe({ url: new URL(`http://127.0.0.1:${silent.address().port}/?k=${KEY}`) }, { timeoutMs: 300 }), false);
  assert.ok(Date.now() - started < 3000);
});

test('preferredPort is the registered port, else the default for the app', () => {
  assert.equal(DEFAULT_PORT, 3431);
  assert.equal(preferredPort(homeWith()), 3431);
  assert.equal(preferredPort(homeWith({ port: 14000 })), 14000);
  assert.equal(preferredPort(homeWith({ port: 0 })), 3431);
  assert.equal(preferredPort(homeWith('not json')), 3431);
});

test('ensureKey creates a private key once and keeps it', () => {
  const home = homeWith();
  const first = ensureKey(home);
  assert.match(first, /^[0-9a-f]{64}$/);
  assert.equal(ensureKey(home), first);
  assert.equal(fs.statSync(keyFile(home)).mode & 0o777, 0o600);
  assert.equal(fs.statSync(path.dirname(keyFile(home))).mode & 0o777, 0o700);
  fs.writeFileSync(keyFile(home), 'short');
  assert.notEqual(ensureKey(home), 'short', 'a key that is not usable is replaced');
});

test('register writes the port and pid; unregister removes only its own', () => {
  const home = homeWith();
  ensureKey(home);
  register(home, 3430, 111);
  assert.deepEqual(JSON.parse(fs.readFileSync(targetFile(home), 'utf8')), { version: 1, port: 3430, pid: 111 });
  assert.equal(readTarget(home).url.port, '3430');
  unregister(home, 222);
  assert.ok(fs.existsSync(targetFile(home)), 'another process\'s registration stays');
  unregister(home, 111);
  assert.equal(fs.existsSync(targetFile(home)), false);
  unregister(home, 111);
});
