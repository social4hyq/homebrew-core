'use strict';

// `orca-app cli`, `orca-app env` and the app-started runtime that `status` and `serve` report.
const assert = require('node:assert/strict');
const childProcess = require('node:child_process');
const fs = require('node:fs');
const http = require('node:http');
const net = require('node:net');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');

const script = path.join(__dirname, '..', 'scripts', 'orca-desktop.sh');
const fakeOrca = path.join(__dirname, 'fake-orca.cjs');
const bash = childProcess.spawnSync('sh', ['-c', 'command -v bash'], { encoding: 'utf8' }).stdout.trim();

function freePort() {
  return new Promise((resolve, reject) => {
    const server = net.createServer();
    server.listen(0, '127.0.0.1', () => { const { port } = server.address(); server.close(() => resolve(port)); });
    server.on('error', reject);
  });
}

async function setup(t, { serving = false } = {}) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'orca-cli-'));
  const home = path.join(dir, 'home');
  const config = path.join(home, '.config/orca-app');
  fs.mkdirSync(config, { recursive: true });
  const bin = path.join(dir, 'orca');
  fs.writeFileSync(bin, `#!/bin/sh\nexec "${process.execPath}" "${fakeOrca}" "$@"\n`, { mode: 0o755 });
  const proc = path.join(dir, 'proc');
  fs.mkdirSync(proc);
  const port = await freePort();
  fs.writeFileSync(path.join(config, 'config.json'), JSON.stringify({ port }));
  let server = null;
  if (serving) {
    server = http.createServer((request, response) => { response.statusCode = request.url.startsWith('/web-index.html') ? 200 : 404; response.end(''); });
    await new Promise((resolve) => server.listen(port, '127.0.0.1', resolve));
  }
  t.after(() => { if (server) server.close(); fs.rmSync(dir, { recursive: true, force: true }); });
  const data = path.join(dir, 'data');
  const profile = path.join(config, 'app-runtime');
  return {
    home, data, profile,
    // The app published its runtime; `pid` is the process it names (present in the fake /proc or not).
    publish: (pid, present = true) => {
      fs.mkdirSync(profile, { recursive: true });
      fs.writeFileSync(path.join(profile, 'orca-runtime.json'), JSON.stringify({ runtimeId: 'r1', pid, transports: [], authToken: 't' }));
      if (present) fs.mkdirSync(path.join(proc, String(pid)));
    },
    // Asynchronous, so the test's own web server keeps answering while the script runs.
    run: (args, extra = {}) => new Promise((resolve) => childProcess.execFile(bash, [script, ...args], {
      timeout: 30000,
      env: {
        PATH: process.env.PATH, HOME: home, ORCA_DESKTOP_ROOT: dir, ORCA_DESKTOP_ORCA_BIN: bin, ORCA_DESKTOP_NODE: process.execPath,
        ORCA_DESKTOP_DATA: data, ORCA_DESKTOP_PROC_ROOT: proc, ...extra,
      },
    }, (error, stdout, stderr) => resolve({ status: error ? (error.code || 1) : 0, stdout, stderr }))),
  };
}

test('env points the CLI at the data root when the app has published nothing', async (t) => {
  const ctx = await setup(t);
  const result = await ctx.run(['env']);
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stdout.trim(), `export ORCA_USER_DATA_PATH=${ctx.data}`);
});

test('env points the CLI at the runtime the app started while it runs', async (t) => {
  const ctx = await setup(t);
  ctx.publish(4242);
  assert.equal((await ctx.run(['env'])).stdout.trim(), `export ORCA_USER_DATA_PATH=${ctx.profile}`);
});

test('a profile left by an app that is gone is not trusted', async (t) => {
  const ctx = await setup(t);
  ctx.publish(4242, false);
  assert.equal((await ctx.run(['env'])).stdout.trim(), `export ORCA_USER_DATA_PATH=${ctx.data}`);
});

test('a profile that is not readable is not trusted either', async (t) => {
  const ctx = await setup(t);
  fs.mkdirSync(ctx.profile, { recursive: true });
  fs.writeFileSync(path.join(ctx.profile, 'orca-runtime.json'), 'junk');
  assert.equal((await ctx.run(['env'])).stdout.trim(), `export ORCA_USER_DATA_PATH=${ctx.data}`);
});

test('env quotes a data root with spaces so eval keeps it whole', async (t) => {
  const ctx = await setup(t);
  const spaced = path.join(path.dirname(ctx.data), 'data with space');
  const out = (await ctx.run(['env'], { ORCA_DESKTOP_DATA: spaced })).stdout.trim();
  const reread = childProcess.spawnSync('sh', ['-c', `${out}; printf %s "$ORCA_USER_DATA_PATH"`], { encoding: 'utf8' }).stdout;
  assert.equal(reread, spaced);
});

test('cli runs orca with the profile of the runtime in use and passes the arguments', async (t) => {
  const ctx = await setup(t);
  assert.equal((await ctx.run(['cli', 'status', '--json'])).stdout.trim(), `fake-orca status --json profile=${ctx.data}`);
  ctx.publish(4242);
  assert.equal((await ctx.run(['cli', 'status'])).stdout.trim(), `fake-orca status profile=${ctx.profile}`);
});

test('cli without the orca binary says so', async (t) => {
  const ctx = await setup(t);
  // A PATH with nothing on it but bash, so `orca` cannot be found.
  const only = fs.mkdtempSync(path.join(os.tmpdir(), 'orca-path-'));
  t.after(() => fs.rmSync(only, { recursive: true, force: true }));
  fs.symlinkSync(bash, path.join(only, 'bash'));
  const result = await ctx.run(['cli', 'status'], { ORCA_DESKTOP_ORCA_BIN: '', PATH: only });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /orca CLI is not installed/);
});

test('status says when the running server is the one the app started', async (t) => {
  const ctx = await setup(t, { serving: true });
  assert.doesNotMatch((await ctx.run(['status'])).stdout, /started by the app/);
  ctx.publish(4242);
  const result = await ctx.run(['status']);
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /started by the app \(CLI: orca-app cli <command>\)/);
});

test('serve starts nothing when the app\'s runtime is up, and points at the CLI', async (t) => {
  const ctx = await setup(t, { serving: true });
  ctx.publish(4242);
  const result = await ctx.run(['serve']);
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /server already healthy/);
  assert.match(result.stdout, /started by the app and ends with it; use `orca-app cli <command>`/);
});

test('help lists cli and env', async (t) => {
  const ctx = await setup(t);
  const help = (await ctx.run(['--help'])).stdout;
  assert.match(help, /cli \[ARGS\.\.\.\]/);
  assert.match(help, /\n  env\s/);
});
