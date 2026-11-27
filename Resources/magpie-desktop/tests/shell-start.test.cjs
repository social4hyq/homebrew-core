'use strict';

// The shell's start-up with and without a registered magpie web.
const assert = require('node:assert/strict');
const childProcess = require('node:child_process');
const fs = require('node:fs');
const http = require('node:http');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');

const appFiles = path.join(__dirname, '..', 'app');
const harness = path.join(__dirname, 'shell-harness.cjs');
const fakeMagpie = path.join(__dirname, 'fake-magpie.cjs');
const KEY = 'c'.repeat(64);

// A copy of the app files with a config that starts the fake magpie, and a HOME.
function setup(t, { backend = true } = {}) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'magpie-shell-'));
  const app = path.join(dir, 'app');
  fs.mkdirSync(app);
  for (const name of fs.readdirSync(appFiles)) fs.copyFileSync(path.join(appFiles, name), path.join(app, name));
  const home = path.join(dir, 'home');
  fs.mkdirSync(home);
  const bin = path.join(dir, 'magpie');
  fs.writeFileSync(bin, `#!/bin/sh\nexec "${process.execPath}" "${fakeMagpie}" "$@"\n`, { mode: 0o755 });
  const log = path.join(dir, 'starts.log');
  fs.writeFileSync(path.join(app, 'config.json'), JSON.stringify(backend ? { backend: bin, host: { HOME: home, PATH: process.env.PATH } } : {}));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  return {
    app, home, log,
    register: (port, key = KEY) => {
      fs.mkdirSync(path.join(home, '.config/magpie-app'), { recursive: true });
      fs.writeFileSync(path.join(home, '.config/magpie-app/web.json'), JSON.stringify({ version: 1, port, pid: 1 }));
      fs.writeFileSync(path.join(home, '.config/magpie-app/web-key'), key + '\n');
    },
    starts: () => (fs.existsSync(log) ? fs.readFileSync(log, 'utf8').trim().split('\n').map((line) => JSON.parse(line)) : []),
    // The app held open: resolves with the child and its first result line.
    hold: () => new Promise((resolve) => {
      const child = childProcess.spawn(process.execPath, [harness, app], {
        env: { PATH: process.env.PATH, HOME: home, TMPDIR: dir, FAKE_MAGPIE_LOG: log, SHELL_HOLD: '1' },
      });
      t.after(() => child.kill());
      let out = '';
      child.stdout.on('data', (chunk) => {
        out += chunk;
        const line = out.split('\n').find((text) => text.startsWith('@@RESULT@@'));
        if (line) resolve({ child, result: JSON.parse(line.slice('@@RESULT@@'.length)), after: () => new Promise((done) => {
          child.stdout.on('data', () => {
            const text = out.split('\n').find((x) => x.startsWith('@@AFTER@@'));
            if (text) done(JSON.parse(text.slice('@@AFTER@@'.length)));
          });
          child.stdin.end();
        }) });
      });
    }),
    run: () => new Promise((resolve) => {
      childProcess.execFile(process.execPath, [harness, app], {
        env: { PATH: process.env.PATH, HOME: home, TMPDIR: dir, FAKE_MAGPIE_LOG: log }, timeout: 40000,
      }, (error, stdout) => {
        const line = stdout.split('\n').find((text) => text.startsWith('@@RESULT@@'));
        resolve(line ? JSON.parse(line.slice('@@RESULT@@'.length)) : { error: String(error), stdout });
      });
    }),
  };
}

// A page that signs the key in, like magpie web does.
function page(t, key = KEY) {
  return new Promise((resolve) => {
    const server = http.createServer((request, response) => {
      response.writeHead(new URL(request.url, 'http://x').searchParams.get('k') === key ? 303 : 401, { location: '/' });
      response.end();
    });
    server.listen(0, '127.0.0.1', () => { t.after(() => server.close()); resolve(server.address().port); });
  });
}

test('opens the registered magpie web and starts no backend of its own', async (t) => {
  const ctx = setup(t);
  const port = await page(t);
  ctx.register(port);
  const result = await ctx.run();
  assert.equal(result.loaded.at(-1), `http://127.0.0.1:${port}/?k=${KEY}`);
  assert.deepEqual(ctx.starts(), []);
});

async function freePort() {
  const server = http.createServer();
  const port = await new Promise((resolve) => server.listen(0, '127.0.0.1', () => resolve(server.address().port)));
  await new Promise((resolve) => server.close(resolve));
  return port;
}

test('starts its own backend on the registered port with the kept key, and registers it', async (t) => {
  const ctx = setup(t);
  const port = await freePort();
  ctx.register(port, 'e'.repeat(64));
  const { result, after } = await ctx.hold();
  assert.deepEqual(ctx.starts(), [['serve', `--web=127.0.0.1:${port}`]]);
  assert.equal(result.loaded.at(-1), `http://127.0.0.1:${port}/?k=${'e'.repeat(64)}`);
  assert.equal(result.registration.port, port);
  assert.notEqual(result.registration.pid, 1, 'the registration is the backend\'s now');
  assert.deepEqual((await after()).registration, null, 'quitting the app takes its registration away');
});

test('creates the key on first use and keeps it for the next start', async (t) => {
  const ctx = setup(t);
  const port = await freePort();
  fs.mkdirSync(path.join(ctx.home, '.config/magpie-app'), { recursive: true });
  fs.writeFileSync(path.join(ctx.home, '.config/magpie-app/web.json'), JSON.stringify({ version: 1, port, pid: 1 }));
  const { result, after } = await ctx.hold();
  const key = fs.readFileSync(path.join(ctx.home, '.config/magpie-app/web-key'), 'utf8').trim();
  assert.match(key, /^[0-9a-f]{64}$/);
  assert.equal(new URL(result.loaded.at(-1)).searchParams.get('k'), key);
  await after();
  fs.writeFileSync(path.join(ctx.home, '.config/magpie-app/web.json'), JSON.stringify({ version: 1, port, pid: 1 }));
  const second = await ctx.hold();
  assert.equal(new URL(second.result.loaded.at(-1)).searchParams.get('k'), key);
  await second.after();
});

test('falls back to any port with a key of its own when the registered port is taken', async (t) => {
  const ctx = setup(t);
  const taken = http.createServer((request, response) => { response.writeHead(401); response.end(); });
  const port = await new Promise((resolve) => taken.listen(0, '127.0.0.1', () => resolve(taken.address().port)));
  t.after(() => taken.close());
  ctx.register(port, 'a'.repeat(64));
  const { result, after } = await ctx.hold();
  assert.deepEqual(ctx.starts().map((args) => args[1]), [`--web=127.0.0.1:${port}`, '--web=127.0.0.1:0']);
  const url = new URL(result.loaded.at(-1));
  assert.notEqual(url.port, String(port));
  assert.notEqual(url.searchParams.get('k'), 'a'.repeat(64));
  assert.equal(result.registration.pid, 1, 'the fallback backend does not replace the registration');
  await after();
});

test('starts its own backend when the registered page refuses the key', async (t) => {
  const ctx = setup(t);
  const port = await page(t, 'd'.repeat(64));
  ctx.register(port);
  const result = await ctx.run();
  assert.notEqual(new URL(result.loaded.at(-1)).port, String(port));
  // The registered port is taken by that page, so the backend ends up on any port.
  assert.deepEqual(ctx.starts().map((args) => args[1]), [`--web=127.0.0.1:${port}`, '--web=127.0.0.1:0']);
});

test('ignores a registration that is not usable', async (t) => {
  const ctx = setup(t);
  fs.mkdirSync(path.join(ctx.home, '.config/magpie-app'), { recursive: true });
  fs.writeFileSync(path.join(ctx.home, '.config/magpie-app/web.json'), JSON.stringify({ port: 'evil.example:80' }));
  fs.writeFileSync(path.join(ctx.home, '.config/magpie-app/web-key'), KEY);
  const result = await ctx.run();
  assert.ok(result.loaded.every((url) => !url.includes('evil.example')));
  assert.equal(ctx.starts()[0][0], 'serve');
  assert.ok(ctx.starts().every((args) => !args.join(' ').includes('evil')));
});

test('the strong-sandbox variant (no backend) still asks for the key by hand', async (t) => {
  const ctx = setup(t, { backend: false });
  const port = await page(t);
  ctx.register(port);
  const result = await ctx.run();
  assert.match(result.loaded.at(-1), /connect\.html#manual$/);
  assert.deepEqual(ctx.starts(), []);
});

test('starts its own backend with a key that is not 64 hex digits, as a plain magpie web leaves in web-key', async (t) => {
  const ctx = setup(t);
  const port = await freePort();
  fs.mkdirSync(path.join(ctx.home, '.config/magpie-app'), { recursive: true });
  fs.writeFileSync(path.join(ctx.home, '.config/magpie-app/web.json'), JSON.stringify({ version: 1, port, pid: 1 }));
  // magpie itself picks a 32-character key; magpie web records it in web-key.
  const key = 'Qk3xV9mZp2LwA7sTn8RbY4uHc6JdE1fG';
  fs.writeFileSync(path.join(ctx.home, '.config/magpie-app/web-key'), key + '\n');
  const { result, after } = await ctx.hold();
  assert.equal(result.loaded.at(-1), `http://127.0.0.1:${port}/?k=${key}`, 'the backend is recognised as ready');
  assert.equal(result.registration.port, port, 'and registered for the terminal');
  assert.deepEqual(ctx.starts(), [['serve', `--web=127.0.0.1:${port}`]]);
  await after();
});
