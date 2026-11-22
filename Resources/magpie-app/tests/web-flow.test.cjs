'use strict';

// `magpie-app web` as a user runs it, against the fake magpie.
const assert = require('node:assert/strict');
const childProcess = require('node:child_process');
const fs = require('node:fs');
const net = require('node:net');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');

const script = path.join(__dirname, '..', 'scripts', 'magpie-app.sh');
const fakeMagpie = path.join(__dirname, 'fake-magpie.cjs');

function freePort() {
  return new Promise((resolve, reject) => {
    const server = net.createServer();
    server.listen(0, '127.0.0.1', () => { const { port } = server.address(); server.close(() => resolve(port)); });
    server.on('error', reject);
  });
}

// A fresh HOME; the processes the test started are stopped before it is removed.
function setup(t) {
  const home = fs.mkdtempSync(path.join(os.tmpdir(), 'magpie-web-'));
  const bin = path.join(home, 'magpie');
  fs.writeFileSync(bin, `#!/bin/sh\nexec "${process.execPath}" "${fakeMagpie}" "$@"\n`, { mode: 0o755 });
  const log = path.join(home, 'starts.log');
  const running = [];
  t.after(() => {
    for (const child of running) child.kill('SIGTERM');
    fs.rmSync(home, { recursive: true, force: true });
  });
  const env = { PATH: process.env.PATH, HOME: home, MAGPIE_APP_BIN: bin, MAGPIE_APP_NODE: process.execPath, FAKE_MAGPIE_LOG: log };
  return {
    home, env,
    starts: () => (fs.existsSync(log) ? fs.readFileSync(log, 'utf8').trim().split('\n').map((line) => JSON.parse(line)) : []),
    run: (args) => childProcess.spawnSync('bash', [script, ...args], { encoding: 'utf8', timeout: 30000, env }),
    // `magpie-app web` stays in the foreground, like magpie web.
    spawnWeb: (args) => {
      const child = childProcess.spawn('bash', [script, 'web', ...args], { env, stdio: 'ignore' });
      running.push(child);
      return child;
    },
  };
}

async function until(check, what) {
  for (let i = 0; i < 100; i += 1) {
    const value = await check();
    if (value) return value;
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  assert.fail(`timed out waiting for ${what}`);
}

const answers = (port, key) => fetch(`http://127.0.0.1:${port}/?k=${key}`, { redirect: 'manual' })
  .then((response) => response.status, () => 0);

test('web starts magpie web on loopback with a key that is kept, and registers it', async (t) => {
  const ctx = setup(t);
  const port = await freePort();
  ctx.spawnWeb(['--port', String(port)]);
  const registration = path.join(ctx.home, '.config/magpie-app/web.json');
  await until(() => fs.existsSync(registration) && ctx.starts().length === 1, 'the registration and the start');
  assert.deepEqual(ctx.starts()[0], ['web', '--addr', `127.0.0.1:${port}`, '--no-open']);
  const keyFile = path.join(ctx.home, '.config/magpie-app/web-key');
  const key = fs.readFileSync(keyFile, 'utf8').trim();
  assert.match(key, /^[0-9a-f]{64}$/);
  assert.equal(fs.statSync(keyFile).mode & 0o777, 0o600);
  assert.equal(fs.statSync(path.dirname(keyFile)).mode & 0o777, 0o700);
  assert.equal(JSON.parse(fs.readFileSync(registration, 'utf8')).port, port);
  assert.equal(await until(() => answers(port, key), 'the page'), 303);
  assert.equal(await answers(port, 'wrong'), 401);
  assert.doesNotMatch(fs.readFileSync(registration, 'utf8'), new RegExp(key), 'the key is not in the registration');
});

test('a second web does not start another magpie and says where the first one is', async (t) => {
  const ctx = setup(t);
  const port = await freePort();
  ctx.spawnWeb(['--port', String(port)]);
  const key = await until(() => {
    try { return fs.readFileSync(path.join(ctx.home, '.config/magpie-app/web-key'), 'utf8').trim(); } catch { return ''; }
  }, 'the key');
  await until(() => answers(port, key), 'the page');
  const second = ctx.run(['web', '--port', String(port)]);
  assert.equal(second.status, 0);
  assert.match(second.stdout, new RegExp(`already running at http://127.0.0.1:${port}`));
  assert.equal(ctx.starts().length, 1);
});

test('web --status reports a missing and a running page', async (t) => {
  const ctx = setup(t);
  const none = ctx.run(['web', '--status']);
  assert.equal(none.status, 1);
  assert.match(none.stdout, /no magpie web is registered/);
  const port = await freePort();
  ctx.spawnWeb(['--port', String(port)]);
  const key = await until(() => {
    try { return fs.readFileSync(path.join(ctx.home, '.config/magpie-app/web-key'), 'utf8').trim(); } catch { return ''; }
  }, 'the key');
  await until(() => answers(port, key), 'the page');
  const live = ctx.run(['web', '--status']);
  assert.equal(live.status, 0);
  assert.match(live.stdout, /already running at/);
  assert.equal(ctx.starts().length, 1, '--status never starts magpie');
});

test('stopping web removes its registration and keeps the key for the next run', async (t) => {
  const ctx = setup(t);
  const port = await freePort();
  const first = ctx.spawnWeb(['--port', String(port)]);
  const registration = path.join(ctx.home, '.config/magpie-app/web.json');
  const keyFile = path.join(ctx.home, '.config/magpie-app/web-key');
  const key = await until(() => {
    try { return fs.readFileSync(keyFile, 'utf8').trim(); } catch { return ''; }
  }, 'the key');
  await until(() => answers(port, key), 'the page');
  first.kill('SIGTERM');
  await until(() => !fs.existsSync(registration), 'the registration to go');
  await until(async () => (await answers(port, key)) === 0, 'the page to stop');
  const second = ctx.spawnWeb(['--port', String(port)]);
  await until(() => ctx.starts().length === 2, 'the second start');
  assert.equal(fs.readFileSync(keyFile, 'utf8').trim(), key);
  assert.equal(await until(() => answers(port, key), 'the page again'), 303);
  second.kill('SIGTERM');
});

test('a stale registration is replaced, not trusted', async (t) => {
  const ctx = setup(t);
  const port = await freePort();
  fs.mkdirSync(path.join(ctx.home, '.config/magpie-app'), { recursive: true });
  fs.writeFileSync(path.join(ctx.home, '.config/magpie-app/web.json'), JSON.stringify({ version: 1, port: await freePort(), pid: 1 }));
  fs.writeFileSync(path.join(ctx.home, '.config/magpie-app/web-key'), 'b'.repeat(64));
  ctx.spawnWeb(['--port', String(port)]);
  await until(() => ctx.starts().length === 1, 'a start');
  assert.equal(JSON.parse(fs.readFileSync(path.join(ctx.home, '.config/magpie-app/web.json'), 'utf8')).port, port);
  assert.equal(await until(() => answers(port, 'b'.repeat(64)), 'the page with the stored key'), 303);
});

test('web refuses a bad port and unknown arguments', (t) => {
  const ctx = setup(t);
  for (const args of [['--port', '0'], ['--port', '99999'], ['--port', 'abc'], ['--bogus']]) {
    const result = ctx.run(['web', ...args]);
    assert.notEqual(result.status, 0, args.join(' '));
  }
  assert.equal(ctx.starts().length, 0);
});

test('usage lists web', (t) => {
  const result = setup(t).run(['--help']);
  assert.match(result.stdout, /web \[--port N\] \[--status\]/);
});
