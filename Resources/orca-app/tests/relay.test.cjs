'use strict';

// The relay that lets the terminal run the orca CLI against the runtime the shell started.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');
const childProcess = require('node:child_process');

const relay = require('../app/relay.cjs');

const fakeOrca = path.join(__dirname, 'fake-orca.cjs');

// A relay running the fake orca, and a way to call it.
async function start(t, { env = {}, execFile } = {}) {
  const home = fs.mkdtempSync(path.join(os.tmpdir(), 'orca-relay-'));
  const bin = path.join(home, 'orca');
  fs.writeFileSync(bin, `#!/bin/sh\nexec "${process.execPath}" "${fakeOrca}" "$@"\n`, { mode: 0o755 });
  const server = await relay.startRelay({ orca: bin, env: { PATH: process.env.PATH, ORCA_USER_DATA_PATH: '/app/data', ...env }, home, execFile });
  t.after(() => { server.stop(); fs.rmSync(home, { recursive: true, force: true }); });
  const call = (route, { method = 'POST', token = server.token, body, headers = {} } = {}) => fetch(`http://127.0.0.1:${server.port}${route}`, {
    method,
    headers: { ...(token === null ? {} : { authorization: 'Bearer ' + token }), 'content-type': 'application/json', ...headers },
    body: body === undefined ? undefined : (typeof body === 'string' ? body : JSON.stringify(body)),
  });
  const run = async (args, extra = {}) => (await call('/run', { body: { args, ...extra } })).json();
  return { home, server, call, run };
}

test('runs the orca CLI with the app\'s own environment and returns what it printed', async (t) => {
  const { run } = await start(t);
  const result = await run(['status', '--json']);
  assert.deepEqual({ code: result.code, timedOut: result.timedOut, stderr: result.stderr }, { code: 0, timedOut: false, stderr: '' });
  assert.equal(result.stdout.trim(), 'fake-orca status --json profile=/app/data');
});

test('the exit code and stderr come back as they were', async (t) => {
  const { run } = await start(t);
  const result = await run(['exit', '3']);
  assert.equal(result.code, 3);
  assert.match(result.stderr, /exiting with 3/);
});

test('arguments are passed as they are, never through a shell', async (t) => {
  const { run } = await start(t);
  const result = await run(['status', '$(touch /tmp/pwned)', 'a b', ';', '&&', '"quoted"']);
  assert.equal(result.stdout.trim(), 'fake-orca status $(touch /tmp/pwned) a b ; && "quoted" profile=/app/data');
});

test('runs from the folder the terminal is in when the app can see it, else from the home folder', async (t) => {
  const { run, home } = await start(t);
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'orca-relay-cwd-'));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  assert.equal((await run(['cwd'], { cwd: dir })).stdout.trim(), fs.realpathSync(dir));
  assert.equal((await run(['cwd'], { cwd: path.join(dir, 'missing') })).stdout.trim(), fs.realpathSync(home));
  assert.equal((await run(['cwd'])).stdout.trim(), fs.realpathSync(home));
});

test('a request without the token, or with another one, is refused before anything runs', async (t) => {
  const calls = [];
  const { call } = await start(t, { execFile: (...args) => { calls.push(args); } });
  assert.equal((await call('/run', { token: null, body: { args: ['status'] } })).status, 401);
  assert.equal((await call('/run', { token: 'wrong', body: { args: ['status'] } })).status, 401);
  assert.equal((await call('/health', { method: 'GET', token: null })).status, 401);
  assert.equal(calls.length, 0);
});

test('health answers with the token; other routes and methods are refused', async (t) => {
  const { call } = await start(t);
  assert.equal((await call('/health', { method: 'GET' })).status, 200);
  assert.equal((await call('/elsewhere', { method: 'GET' })).status, 404);
  assert.equal((await call('/run', { method: 'GET' })).status, 405);
  assert.equal((await call('/run', { body: { args: ['status'] }, headers: { 'content-type': 'text/plain' } })).status, 415);
});

test('bad requests are refused with a reason', async (t) => {
  const { call } = await start(t);
  const refuse = async (body) => { const r = await call('/run', { body }); return [r.status, (await r.json()).error]; };
  assert.deepEqual((await refuse('not json'))[0], 400);
  assert.equal((await refuse({}))[0], 400);
  assert.equal((await refuse({ args: [] }))[0], 400);
  assert.equal((await refuse({ args: 'status' }))[0], 400);
  assert.equal((await refuse({ args: ['status', 7] }))[0], 400);
  assert.equal((await refuse({ args: ['a\0b'] }))[0], 400);
  assert.equal((await refuse({ args: new Array(201).fill('x') }))[0], 400);
  assert.equal((await refuse({ args: ['x'.repeat(70000)] }))[0], 400);
  assert.equal((await refuse({ args: ['status'], cwd: 'relative' }))[0], 400);
  assert.equal((await refuse({ args: ['status'], timeoutMs: 5 }))[0], 400);
  assert.equal((await refuse({ args: ['status'], timeoutMs: relay.MAX_TIMEOUT_MS + 1 }))[0], 400);
});

test('commands that would start another runtime are not available', async (t) => {
  const calls = [];
  const { call } = await start(t, { execFile: (...args) => { calls.push(args); } });
  for (const command of relay.DENIED) {
    const response = await call('/run', { body: { args: [command, '--port', '1'] } });
    assert.equal(response.status, 400);
    assert.match((await response.json()).error, new RegExp(command));
  }
  assert.equal(calls.length, 0);
});

test('a request that is too large is refused', async (t) => {
  const { call } = await start(t);
  const response = await call('/run', { body: JSON.stringify({ args: ['status'], pad: 'x'.repeat(relay.MAX_BODY + 10) }) }).catch((error) => error);
  assert.ok(response instanceof Error || response.status === 413);
});

test('a command that runs too long is stopped and reported', async (t) => {
  const { run } = await start(t);
  const result = await run(['sleep', '20000'], { timeoutMs: 1000 });
  assert.equal(result.timedOut, true);
  assert.notEqual(result.code, 0);
});

test('output past the limit is cut off with an error code, not buffered without end', async (t) => {
  const { run } = await start(t);
  const result = await run(['big', String(9 * 1024 * 1024)]);
  assert.notEqual(result.code, 0);
});

test('a CLI that cannot be started is reported', async (t) => {
  const home = fs.mkdtempSync(path.join(os.tmpdir(), 'orca-relay-'));
  const server = await relay.startRelay({ orca: path.join(home, 'no-such-orca'), env: {}, home });
  t.after(() => { server.stop(); fs.rmSync(home, { recursive: true, force: true }); });
  const response = await fetch(`http://127.0.0.1:${server.port}/run`, {
    method: 'POST', headers: { authorization: 'Bearer ' + server.token, 'content-type': 'application/json' }, body: JSON.stringify({ args: ['status'] }),
  });
  const result = await response.json();
  assert.equal(result.spawnError, 'ENOENT');
  assert.notEqual(result.code, 0);
});

test('commands run side by side without mixing their output', async (t) => {
  const { run } = await start(t);
  const results = await Promise.all(['one', 'two', 'three', 'four'].map((word) => run(['status', word])));
  assert.deepEqual(results.map((r) => r.stdout.trim()), ['one', 'two', 'three', 'four'].map((w) => `fake-orca status ${w} profile=/app/data`));
});

test('the relay listens on loopback only', async (t) => {
  const { server } = await start(t);
  const net = require('node:net');
  const connect = (host) => new Promise((resolve) => {
    const socket = net.connect({ port: server.port, host, timeout: 2000 });
    socket.on('connect', () => { socket.destroy(); resolve('connected'); });
    socket.on('error', (error) => resolve(error.code));
    socket.on('timeout', () => { socket.destroy(); resolve('timeout'); });
  });
  assert.equal(await connect('127.0.0.1'), 'connected');
  // Another address of this machine, when it has one, must not reach the relay.
  const outside = Object.values(os.networkInterfaces()).flat().find((entry) => entry && entry.family === 'IPv4' && !entry.internal);
  if (outside) assert.notEqual(await connect(outside.address), 'connected');
});

test('publish writes where the relay is, readRelay reads it back, unpublish removes only its own', (t) => {
  const home = fs.mkdtempSync(path.join(os.tmpdir(), 'orca-relay-reg-'));
  t.after(() => fs.rmSync(home, { recursive: true, force: true }));
  const token = 'a'.repeat(48);
  assert.equal(relay.publish(home, { port: 40123, token, pid: 77, runtimeId: 'r1' }), true);
  assert.equal(relay.relayFile(home), path.join(home, '.config/orca-app/app-runtime/relay.json'));
  assert.deepEqual(relay.readRelay(home), { port: 40123, token, pid: 77, runtimeId: 'r1' });
  assert.equal(relay.unpublish(home, 78), true, 'another process leaves it alone');
  assert.ok(fs.existsSync(relay.relayFile(home)));
  assert.equal(relay.unpublish(home, 77), true);
  assert.equal(fs.existsSync(relay.relayFile(home)), false);
  assert.equal(relay.readRelay(home), null);
});

test('readRelay refuses a registration that is not usable', (t) => {
  const home = fs.mkdtempSync(path.join(os.tmpdir(), 'orca-relay-reg-'));
  t.after(() => fs.rmSync(home, { recursive: true, force: true }));
  const write = (value) => { fs.mkdirSync(path.dirname(relay.relayFile(home)), { recursive: true }); fs.writeFileSync(relay.relayFile(home), typeof value === 'string' ? value : JSON.stringify(value)); };
  const good = { version: 1, port: 40123, token: 'b'.repeat(48), pid: 5 };
  assert.ok(relay.readRelay(home) === null);
  write('junk'); assert.equal(relay.readRelay(home), null);
  write({ ...good, version: 2 }); assert.equal(relay.readRelay(home), null);
  write({ ...good, port: 0 }); assert.equal(relay.readRelay(home), null);
  write({ ...good, port: 70000 }); assert.equal(relay.readRelay(home), null);
  write({ ...good, token: 'short' }); assert.equal(relay.readRelay(home), null);
  write({ ...good, token: 'ZZ'.repeat(24) }); assert.equal(relay.readRelay(home), null);
  write(good); assert.equal(relay.readRelay(home).port, 40123);
});
