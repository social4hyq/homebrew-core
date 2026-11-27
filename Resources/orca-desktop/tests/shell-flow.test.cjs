'use strict';

// The shell's real main.cjs against a stand-in for electron and a fake orca: which page it
// opens for a terminal's runtime and for its own, when it drops the web client's saved
// server (so no "different server" question appears), what it registers for the terminal's
// CLI, and what quitting does.
const assert = require('node:assert/strict');
const childProcess = require('node:child_process');
const fs = require('node:fs');
const http = require('node:http');
const net = require('node:net');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');

const attach = require('../app/attach.cjs');
const { pairingLink } = require('./fake-orca.cjs');

const appFiles = path.join(__dirname, '..', 'app');
const harness = path.join(__dirname, 'shell-harness.cjs');
const fakeOrca = path.join(__dirname, 'fake-orca.cjs');

function freePort() {
  return new Promise((resolve, reject) => {
    const server = net.createServer();
    server.listen(0, '127.0.0.1', () => { const { port } = server.address(); server.close(() => resolve(port)); });
    server.on('error', reject);
  });
}

// A copy of the app files, a HOME and a fake orca.
async function setup(t) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'orca-shell-'));
  const app = path.join(dir, 'app');
  fs.mkdirSync(app);
  for (const name of fs.readdirSync(appFiles)) fs.copyFileSync(path.join(appFiles, name), path.join(app, name));
  const home = path.join(dir, 'home');
  fs.mkdirSync(path.join(home, '.config/orca-app'), { recursive: true });
  const bin = path.join(dir, 'orca');
  fs.writeFileSync(bin, `#!/bin/sh\nexec "${process.execPath}" "${fakeOrca}" "$@"\n`, { mode: 0o755 });
  const port = await freePort();
  fs.writeFileSync(path.join(app, 'config.json'), JSON.stringify({ port, orca: bin, host: { home, path: process.env.PATH } }));
  const children = [];
  const servers = [];
  t.after(() => {
    for (const child of children) child.kill('SIGTERM'); // the harness stops the runtime it started
    for (const server of servers) server.close();
    fs.rmSync(dir, { recursive: true, force: true });
  });
  const stateFile = path.join(home, '.cache/orca-desktop/attach.json');
  return {
    dir, app, home, port, stateFile,
    profileFile: path.join(home, '.config/orca-app/app-runtime/relay.json'),
    setState: (state) => { fs.mkdirSync(path.dirname(stateFile), { recursive: true }); fs.writeFileSync(stateFile, JSON.stringify(state)); },
    // A runtime a terminal started: serving on the port, with its ready record in server.ready.json.
    terminalRuntime: async ({ installation = 'terminal-host', runtimeId = 'runtime-terminal-1' } = {}) => {
      const server = http.createServer((request, response) => {
        response.statusCode = request.url.startsWith('/web-index.html') ? 200 : 404;
        response.end('');
      });
      await new Promise((resolve) => server.listen(port, '127.0.0.1', resolve));
      servers.push(server);
      const link = pairingLink(port, installation);
      fs.writeFileSync(path.join(home, '.config/orca-app/server.ready.json'), JSON.stringify({
        type: 'orca_server_ready', schemaVersion: 1, runtimeId, endpoint: `ws://127.0.0.1:${port}`,
        pairing: { available: true, webClientUrl: link },
      }) + '\n');
      return link;
    },
    start: (env = {}) => {
      const child = childProcess.spawn(process.execPath, [harness, app], {
        env: { PATH: process.env.PATH, HOME: home, TMPDIR: dir, ...env }, stdio: ['pipe', 'pipe', 'pipe'],
      });
      children.push(child);
      const events = [];
      let buffer = '';
      child.stdout.on('data', (chunk) => {
        buffer += chunk;
        let at;
        while ((at = buffer.indexOf('\n')) >= 0) {
          const line = buffer.slice(0, at);
          buffer = buffer.slice(at + 1);
          if (line.startsWith('@@EVENT@@')) events.push(JSON.parse(line.slice('@@EVENT@@'.length)));
        }
      });
      const exited = new Promise((resolve) => child.on('exit', resolve));
      return { child, events, exited, send: (line) => child.stdin.write(line + '\n') };
    },
  };
}

async function until(check, what) {
  for (let i = 0; i < 150; i += 1) {
    const value = check();
    if (value) return value;
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  assert.fail('timed out waiting for ' + what);
}

const isLink = (event) => event.type === 'load' && event.url.includes('#pairing=');
const loads = (run) => run.events.filter((event) => event.type === 'load').map((event) => event.url);

test('a terminal runtime for another host: the saved server is dropped first, then the link opens', async (t) => {
  const ctx = await setup(t);
  const link = await ctx.terminalRuntime();
  ctx.setState({ lastPairedRuntimeId: null, lastTriedRuntimeId: null, pairedHostId: 'installation:own-host' });
  const run = ctx.start();
  await until(() => run.events.some(isLink), 'the link');
  const urls = loads(run);
  assert.deepEqual(urls, [`http://127.0.0.1:${ctx.port}/__orca-shell__`, link]);
  const script = run.events.find((event) => event.type === 'js').code;
  assert.ok(script.includes(attach.SAVED_SERVER_KEY) && script.includes('removeItem'));
  // The clearing comes between the two loads.
  const order = run.events.map((event) => event.type);
  assert.deepEqual(order.filter((type) => type === 'load' || type === 'js'), ['load', 'js', 'load']);
});

test('a link for the host the web client is already paired with is opened as it is', async (t) => {
  const ctx = await setup(t);
  const link = await ctx.terminalRuntime({ installation: 'terminal-host' });
  ctx.setState({ lastPairedRuntimeId: null, lastTriedRuntimeId: null, pairedHostId: 'installation:terminal-host' });
  const run = ctx.start();
  await until(() => run.events.some(isLink), 'the link');
  assert.deepEqual(loads(run), [link]);
  assert.equal(run.events.some((event) => event.type === 'js'), false);
});

test('a first pairing, with nothing recorded, also drops whatever the client saved', async (t) => {
  const ctx = await setup(t);
  const link = await ctx.terminalRuntime();
  const run = ctx.start();
  await until(() => run.events.some(isLink), 'the link');
  assert.equal(loads(run).at(-1), link);
  assert.equal(run.events.filter((event) => event.type === 'js').length, 1);
});

test('a runtime already paired is opened plain and the saved server is left alone', async (t) => {
  const ctx = await setup(t);
  await ctx.terminalRuntime({ runtimeId: 'runtime-terminal-1' });
  ctx.setState({ lastPairedRuntimeId: 'runtime-terminal-1', lastTriedRuntimeId: null, pairedHostId: 'installation:terminal-host' });
  const run = ctx.start();
  await until(() => run.events.some((event) => event.type === 'load'), 'a page');
  assert.deepEqual(loads(run), [`http://127.0.0.1:${ctx.port}/web-index.html`]);
  assert.equal(run.events.some((event) => event.type === 'js'), false);
});

test('the pairing is recorded once the runtime logs a connection, with the host it is for', async (t) => {
  const ctx = await setup(t);
  await ctx.terminalRuntime({ runtimeId: 'runtime-terminal-1' });
  const run = ctx.start();
  await until(() => run.events.some(isLink), 'the link');
  assert.equal(attach.readState(ctx.stateFile).lastTriedRuntimeId, 'runtime-terminal-1');
  fs.appendFileSync(path.join(ctx.home, '.config/orca-app/server.ready.json'),
    `${new Date(Date.now() + 5000).toISOString()} [runtime-rpc] client connected device=d1 scope=runtime\n`);
  await until(() => attach.readState(ctx.stateFile).lastPairedRuntimeId === 'runtime-terminal-1', 'the recorded pairing');
  assert.equal(attach.readState(ctx.stateFile).pairedHostId, 'installation:terminal-host');
});

test('with nothing serving the shell starts its own runtime, opens its link and registers a relay for the CLI', async (t) => {
  const ctx = await setup(t);
  const run = ctx.start();
  const link = await until(() => run.events.find(isLink), 'the link');
  assert.match(link.url, new RegExp(`^http://127\\.0\\.0\\.1:${ctx.port}/web-index\\.html#pairing=`));
  assert.equal(attach.hostIdOf(link.url), 'installation:own-host');
  const registered = await until(() => fs.existsSync(ctx.profileFile) && JSON.parse(fs.readFileSync(ctx.profileFile, 'utf8')), 'the relay registration');
  assert.equal(registered.version, 1);
  assert.equal(registered.runtimeId, 'runtime-own-1');
  assert.ok(registered.port > 0 && registered.port !== ctx.port);
  assert.match(registered.token, /^[0-9a-f]{48}$/);
  assert.ok(registered.pid > 0);
  // The terminal's side: a command run through the relay reaches the runtime's own data root.
  const response = await fetch(`http://127.0.0.1:${registered.port}/run`, {
    method: 'POST', headers: { authorization: 'Bearer ' + registered.token, 'content-type': 'application/json' },
    body: JSON.stringify({ args: ['status', '--json'] }),
  });
  const result = await response.json();
  assert.equal(result.code, 0);
  assert.match(result.stdout, /fake-orca status --json profile=.*orca-data/, 'the CLI is pointed at the runtime the shell started');
  run.send('end');
  await run.exited;
});

test('switching from a terminal runtime to the shell\'s own drops the saved server too', async (t) => {
  const ctx = await setup(t);
  ctx.setState({ lastPairedRuntimeId: 'runtime-terminal-1', lastTriedRuntimeId: null, pairedHostId: 'installation:terminal-host' });
  const run = ctx.start();
  await until(() => run.events.some(isLink), 'the link');
  assert.deepEqual(run.events.map((event) => event.type).filter((type) => type === 'load' || type === 'js'), ['load', 'js', 'load']);
});

test('the shell\'s own runtime on the same host keeps the saved server, and a terminal runtime is link again afterwards', async (t) => {
  const ctx = await setup(t);
  ctx.setState({ lastPairedRuntimeId: 'runtime-terminal-1', lastTriedRuntimeId: null, pairedHostId: 'installation:own-host' });
  const run = ctx.start();
  await until(() => run.events.some(isLink), 'the link');
  assert.equal(run.events.some((event) => event.type === 'js'), false);
  fs.mkdirSync(path.dirname(ctx.stateFile), { recursive: true });
  // Its connection is logged; the shell records that the client now talks to its own runtime.
  const log = path.join(ctx.home, '.cache/orca-desktop/serve.log');
  fs.appendFileSync(log, `${new Date(Date.now() + 5000).toISOString()} [runtime-rpc] client connected device=d1 scope=runtime\n`);
  await until(() => attach.readState(ctx.stateFile).lastPairedRuntimeId === null && attach.readState(ctx.stateFile).pairedHostId === 'installation:own-host', 'the own pairing');
  run.send('end');
  await run.exited;
});

test('the relay is gone with the shell and refuses requests afterwards', async (t) => {
  const ctx = await setup(t);
  const run = ctx.start();
  const registered = await until(() => fs.existsSync(ctx.profileFile) && JSON.parse(fs.readFileSync(ctx.profileFile, 'utf8')), 'the relay registration');
  run.send('quit');
  await run.exited;
  assert.equal(fs.existsSync(ctx.profileFile), false);
  const refused = await fetch(`http://127.0.0.1:${registered.port}/health`, { headers: { authorization: 'Bearer ' + registered.token } }).then(() => 'answered', () => 'refused');
  assert.equal(refused, 'refused');
});

test('quitting without terminals in the shell\'s own runtime exits at once and takes the profile away', async (t) => {
  const ctx = await setup(t);
  const run = ctx.start({ FAKE_TERMINALS: '0' });
  await until(() => fs.existsSync(ctx.profileFile), 'the relay registration');
  run.send('quit');
  await run.exited;
  assert.equal(run.events.some((event) => event.type === 'dialog'), false);
  assert.deepEqual(run.events.find((event) => event.type === 'exit'), { type: 'exit', code: 0 });
  assert.equal(fs.existsSync(ctx.profileFile), false);
});

test('quitting asks first when the shell\'s own runtime holds terminals; cancel keeps everything', async (t) => {
  const ctx = await setup(t);
  const run = ctx.start({ FAKE_TERMINALS: '2', DIALOG_RESPONSE: '0' });
  await until(() => fs.existsSync(ctx.profileFile), 'the relay registration');
  run.send('quit');
  const dialog = await until(() => run.events.find((event) => event.type === 'dialog'), 'the question');
  assert.match(dialog.options.message, /2 个终端/);
  assert.deepEqual(dialog.options.buttons, ['取消', '仍然退出']);
  await new Promise((resolve) => setTimeout(resolve, 400));
  assert.equal(run.events.some((event) => event.type === 'exit'), false);
  assert.equal(fs.existsSync(ctx.profileFile), true);
  run.send('end');
  await run.exited;
});

test('confirming the question quits and ends the runtime', async (t) => {
  const ctx = await setup(t);
  const run = ctx.start({ FAKE_TERMINALS: '3', DIALOG_RESPONSE: '1' });
  await until(() => fs.existsSync(ctx.profileFile), 'the relay registration');
  run.send('quit');
  await run.exited;
  assert.ok(run.events.some((event) => event.type === 'dialog'));
  assert.ok(run.events.some((event) => event.type === 'exit'));
  assert.equal(fs.existsSync(ctx.profileFile), false);
});

test('a second click while the question is open quits anyway', async (t) => {
  const ctx = await setup(t);
  const run = ctx.start({ FAKE_TERMINALS: '1', DIALOG_HOLD: '1' });
  await until(() => fs.existsSync(ctx.profileFile), 'the relay registration');
  run.send('quit');
  await until(() => run.events.some((event) => event.type === 'dialog'), 'the question');
  run.send('quit');
  await run.exited;
  assert.ok(run.events.some((event) => event.type === 'exit'));
});

test('a CLI that does not answer does not block quitting', async (t) => {
  const ctx = await setup(t);
  const run = ctx.start({ FAKE_TERMINALS: 'fail' });
  await until(() => fs.existsSync(ctx.profileFile), 'the relay registration');
  run.send('quit');
  await run.exited;
  assert.equal(run.events.some((event) => event.type === 'dialog'), false);
  assert.ok(run.events.some((event) => event.type === 'exit'));
});

test('quitting never asks about, or stops, a runtime a terminal started', async (t) => {
  const ctx = await setup(t);
  await ctx.terminalRuntime();
  const run = ctx.start({ FAKE_TERMINALS: '5' });
  await until(() => run.events.some(isLink), 'the link');
  run.send('quit');
  await run.exited;
  assert.equal(run.events.some((event) => event.type === 'dialog'), false);
  assert.equal(fs.existsSync(ctx.profileFile), false);
});
