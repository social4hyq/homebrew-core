'use strict';

// `orca-app cli`, `orca-app env` and the app-started runtime that `status` and `serve` report,
// reached through the app's relay.
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
const relay = require('../app/relay.cjs');
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
  const registration = path.join(config, 'app-runtime', 'relay.json');
  return {
    home, data, registration, bin,
    // The app's relay, running the fake orca as the app would; `pid` is the app process the
    // registration names (present in the fake /proc or not).
    startRelay: async (pid = 4242, { present = true, publish = true } = {}) => {
      const server = await relay.startRelay({
        orca: bin, env: { PATH: process.env.PATH, ORCA_USER_DATA_PATH: '/app/sandbox/orca-data' }, home,
      });
      t.after(() => server.stop());
      if (publish) relay.publish(home, { port: server.port, token: server.token, pid, runtimeId: 'r1' });
      if (present) fs.mkdirSync(path.join(proc, String(pid)));
      return server;
    },
    // Asynchronous, so the test's own web server keeps answering while the script runs.
    run: (args, extra = {}, cwd = undefined) => new Promise((resolve) => childProcess.execFile(bash, [script, ...args], {
      timeout: 30000, cwd,
      env: {
        PATH: process.env.PATH, HOME: home, ORCA_DESKTOP_ROOT: dir, ORCA_DESKTOP_ORCA_BIN: bin, ORCA_DESKTOP_NODE: process.execPath,
        ORCA_DESKTOP_DATA: data, ORCA_DESKTOP_PROC_ROOT: proc, ...extra,
      },
    }, (error, stdout, stderr) => resolve({ status: error ? (error.code || 1) : 0, stdout, stderr }))),
  };
}

test('env points the CLI at the data root when the app has registered nothing', async (t) => {
  const ctx = await setup(t);
  const result = await ctx.run(['env']);
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stdout.trim(), `export ORCA_USER_DATA_PATH=${ctx.data}`);
});

test('env defines an orca function that goes through the app while its runtime runs', async (t) => {
  const ctx = await setup(t);
  await ctx.startRelay();
  const out = (await ctx.run(['env'])).stdout.trim();
  assert.equal(out, 'orca() { command orca-app cli "$@"; }');
  assert.equal(childProcess.spawnSync('sh', ['-c', `${out}; type orca >/dev/null && echo defined`], { encoding: 'utf8' }).stdout.trim(), 'defined');
});

test('a registration left by an app that is gone is not trusted', async (t) => {
  const ctx = await setup(t);
  await ctx.startRelay(4242, { present: false });
  assert.equal((await ctx.run(['env'])).stdout.trim(), `export ORCA_USER_DATA_PATH=${ctx.data}`);
});

test('a registration left by a killed app is removed by the next env or cli', async (t) => {
  const ctx = await setup(t);
  await ctx.startRelay(4242, { present: false });
  assert.equal(fs.existsSync(ctx.registration), true);
  assert.equal((await ctx.run(['env'])).stdout.trim(), `export ORCA_USER_DATA_PATH=${ctx.data}`);
  assert.equal(fs.existsSync(ctx.registration), false, 'env removed it');
  await ctx.startRelay(4343, { present: false });
  assert.equal((await ctx.run(['cli', 'status'])).stdout.trim(), `fake-orca status profile=${ctx.data}`);
  assert.equal(fs.existsSync(ctx.registration), false, 'cli removed it');
});

test('a registration of an app that is running is kept, even when its relay does not answer', async (t) => {
  const ctx = await setup(t);
  const server = await ctx.startRelay();
  server.stop();
  await new Promise((resolve) => setTimeout(resolve, 100));
  await ctx.run(['env']);
  assert.equal(fs.existsSync(ctx.registration), true);
});

// The removal runs in a Node step inside the script; whatever it prints would reach the terminal.
test('removing a killed app\'s registration prints nothing on stderr, from env and from cli', async (t) => {
  const ctx = await setup(t);
  await ctx.startRelay(4242, { present: false });
  const env = await ctx.run(['env']);
  assert.equal(env.status, 0, env.stderr);
  assert.equal(env.stdout.trim(), `export ORCA_USER_DATA_PATH=${ctx.data}`);
  assert.equal(env.stderr, '', 'env writes nothing to stderr');
  await ctx.startRelay(4343, { present: false });
  const cli = await ctx.run(['cli', 'status']);
  assert.equal(cli.status, 0, cli.stderr);
  assert.equal(cli.stdout.trim(), `fake-orca status profile=${ctx.data}`);
  assert.equal(cli.stderr, '', 'cli writes nothing to stderr');
});

test('a running app\'s registration is kept without anything on stderr', async (t) => {
  const ctx = await setup(t);
  await ctx.startRelay();
  const result = await ctx.run(['env']);
  assert.match(result.stdout, /orca\(\) \{ command orca-app cli/);
  assert.equal(result.stderr, '');
});

test('a registration that cannot be judged (no pid, or unreadable) is left alone', async (t) => {
  const ctx = await setup(t);
  fs.mkdirSync(path.dirname(ctx.registration), { recursive: true });
  for (const content of ['junk', JSON.stringify({ version: 1, port: 1, token: 'a'.repeat(32) })]) {
    fs.writeFileSync(ctx.registration, content);
    await ctx.run(['env']);
    assert.equal(fs.readFileSync(ctx.registration, 'utf8'), content);
  }
});

test('a registration whose relay does not answer is not trusted either', async (t) => {
  const ctx = await setup(t);
  const server = await ctx.startRelay();
  server.stop();
  await new Promise((resolve) => setTimeout(resolve, 100));
  assert.equal((await ctx.run(['env'])).stdout.trim(), `export ORCA_USER_DATA_PATH=${ctx.data}`);
  assert.equal((await ctx.run(['cli', 'status'])).stdout.trim(), `fake-orca status profile=${ctx.data}`);
});

test('a registration that is not readable is not trusted', async (t) => {
  const ctx = await setup(t);
  fs.mkdirSync(path.dirname(ctx.registration), { recursive: true });
  fs.writeFileSync(ctx.registration, 'junk');
  assert.equal((await ctx.run(['env'])).stdout.trim(), `export ORCA_USER_DATA_PATH=${ctx.data}`);
});

test('env quotes a data root with spaces so eval keeps it whole', async (t) => {
  const ctx = await setup(t);
  const spaced = path.join(path.dirname(ctx.data), 'data with space');
  const out = (await ctx.run(['env'], { ORCA_DESKTOP_DATA: spaced })).stdout.trim();
  const reread = childProcess.spawnSync('sh', ['-c', `${out}; printf %s "$ORCA_USER_DATA_PATH"`], { encoding: 'utf8' }).stdout;
  assert.equal(reread, spaced);
});

test('cli without a relay runs orca against the data root of `orca-app serve`', async (t) => {
  const ctx = await setup(t);
  assert.equal((await ctx.run(['cli', 'status', '--json'])).stdout.trim(), `fake-orca status --json profile=${ctx.data}`);
});

test('cli through the app\'s relay runs the command in the app, with its runtime, and prints the output', async (t) => {
  const ctx = await setup(t);
  await ctx.startRelay();
  const result = await ctx.run(['cli', 'status', '--json', 'with space', '$(nope)']);
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stdout.trim(), 'fake-orca status --json with space $(nope) profile=/app/sandbox/orca-data');
});

test('cli through the relay passes the folder the terminal is in', async (t) => {
  const ctx = await setup(t);
  await ctx.startRelay();
  const here = fs.mkdtempSync(path.join(os.tmpdir(), 'orca-cli-here-'));
  t.after(() => fs.rmSync(here, { recursive: true, force: true }));
  const result = await ctx.run(['cli', 'cwd'], {}, here);
  assert.equal(result.stdout.trim(), fs.realpathSync(here));
});

test('cli through the relay returns the command\'s exit code and its stderr', async (t) => {
  const ctx = await setup(t);
  await ctx.startRelay();
  const result = await ctx.run(['cli', 'exit', '7']);
  assert.equal(result.status, 7);
  assert.match(result.stderr, /exiting with 7/);
});

test('cli through the relay says so when the app refuses the command', async (t) => {
  const ctx = await setup(t);
  await ctx.startRelay();
  const result = await ctx.run(['cli', 'serve', '--port', '1']);
  assert.equal(result.status, 70);
  assert.match(result.stderr, /the app refused the command: orca serve is not available/);
});

test('cli without the orca binary says so when the app\'s runtime is not running', async (t) => {
  const ctx = await setup(t);
  // A PATH with nothing on it but bash, so `orca` cannot be found.
  const only = fs.mkdtempSync(path.join(os.tmpdir(), 'orca-path-'));
  t.after(() => fs.rmSync(only, { recursive: true, force: true }));
  fs.symlinkSync(bash, path.join(only, 'bash'));
  const result = await ctx.run(['cli', 'status'], { ORCA_DESKTOP_ORCA_BIN: '', PATH: only });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /orca CLI is not installed/);
});

test('cli through the relay needs no orca on the terminal\'s side', async (t) => {
  const ctx = await setup(t);
  await ctx.startRelay();
  const only = fs.mkdtempSync(path.join(os.tmpdir(), 'orca-path-'));
  t.after(() => fs.rmSync(only, { recursive: true, force: true }));
  fs.symlinkSync(bash, path.join(only, 'bash'));
  const result = await ctx.run(['cli', 'status'], { ORCA_DESKTOP_ORCA_BIN: '', PATH: only });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /profile=\/app\/sandbox\/orca-data/);
});

test('status says when the running server is the one the app started', async (t) => {
  const ctx = await setup(t, { serving: true });
  assert.doesNotMatch((await ctx.run(['status'])).stdout, /started by the app/);
  await ctx.startRelay();
  const result = await ctx.run(['status']);
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /started by the app \(CLI: orca-app cli <command>\)/);
});

test('serve starts nothing when the app\'s runtime is up, and points at the CLI', async (t) => {
  const ctx = await setup(t, { serving: true });
  await ctx.startRelay();
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
