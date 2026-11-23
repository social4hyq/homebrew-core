'use strict';

// End to end with the fake codex: the bridge against a shared server, and
// `codex-app serve | status | stop | tui` as a user runs them.
const assert = require('node:assert/strict');
const childProcess = require('node:child_process');
const fs = require('node:fs');
const net = require('node:net');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');

const bridgeScript = path.join(__dirname, '..', 'app', 'owl-codex-bridge.cjs');
const script = path.join(__dirname, '..', 'scripts', 'codex-app.sh');
const fakeCodex = path.join(__dirname, 'fake-codex.cjs');

// A fresh HOME; when the test ends any server it started is stopped, then it is removed.
function tempHome(t) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'codex-share-'));
  t.after(() => {
    run(dir, ['serve', '--stop']);
    fs.rmSync(dir, { recursive: true, force: true });
  });
  return dir;
}

function freePort() {
  return new Promise((resolve, reject) => {
    const server = net.createServer();
    server.listen(0, '127.0.0.1', () => { const { port } = server.address(); server.close(() => resolve(port)); });
    server.on('error', reject);
  });
}

// An executable `codex` that runs fake-codex.cjs with this Node.
function fakeCli(home) {
  const file = path.join(home, 'codex');
  fs.writeFileSync(file, `#!/bin/sh\nexec "${process.execPath}" "${fakeCodex}" "$@"\n`, { mode: 0o755 });
  return file;
}

function run(home, args, extra = {}) {
  return childProcess.spawnSync('bash', [script, ...args], {
    encoding: 'utf8',
    timeout: 60000,
    env: {
      PATH: process.env.PATH, HOME: home,
      CHATGPT_APP_UNSIGNED_HAP: '/unused', CHATGPT_APP_INSTALL_SCRIPT: '/unused',
      CODEX_APP_CODEX_CLI: fakeCli(home), CODEX_APP_NODE: process.execPath, ...extra,
    },
  });
}

// Send request lines to the bridge and collect the reply lines.
function talk(bridgeArgs, lines, env = {}) {
  return new Promise((resolve) => {
    const child = childProcess.spawn(process.execPath, [bridgeScript, ...bridgeArgs], { env: { ...process.env, ...env } });
    let out = ''; let err = '';
    child.stdout.on('data', (d) => { out += d; });
    child.stderr.on('data', (d) => { err += d; });
    child.on('exit', (code) => resolve({ code, out: out.trim().split('\n').filter(Boolean).map((l) => JSON.parse(l)), err }));
    for (const line of lines) child.stdin.write(line + '\n');
    setTimeout(() => child.stdin.end(), 700);
  });
}

function writeEndpoint(home, port) {
  const dir = path.join(home, '.config', 'codex-app');
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, 'ws-token'), 'secret-token\n');
  fs.writeFileSync(path.join(dir, 'server.json'), JSON.stringify({ version: 1, port, tokenFile: path.join(dir, 'ws-token') }));
  return path.join(dir, 'server.json');
}

const request = JSON.stringify({ id: 1, method: 'initialize' });

test('serve starts one shared server, is idempotent, and stop ends it', async (t) => {
  const home = tempHome(t);
  const port = await freePort();
  assert.equal(run(home, ['serve', '--status']).status, 1, 'not running yet');
  const started = run(home, ['serve', '--port', String(port)]);
  assert.equal(started.status, 0, started.stderr);
  assert.match(started.stdout, new RegExp(`serving at ws://127.0.0.1:${port}`));
  const info = JSON.parse(fs.readFileSync(path.join(home, '.config/codex-app/server.json'), 'utf8'));
  assert.equal(info.port, port);
  assert.equal(info.version, 1);
  assert.equal(fs.statSync(path.join(home, '.config/codex-app/ws-token')).mode & 0o077, 0, 'token is private');
  const again = run(home, ['serve', '--port', String(port + 1)]);
  assert.equal(again.status, 0);
  assert.match(again.stdout, new RegExp(`serving at ws://127.0.0.1:${port} \\(pid ${info.pid}\\)`), 'same server, not a second one');
  assert.equal(run(home, ['serve', '--status']).status, 0);
  assert.equal(run(home, ['serve', '--stop']).status, 0);
  assert.equal(fs.existsSync(path.join(home, '.config/codex-app/server.json')), false);
  assert.equal(run(home, ['serve', '--status']).status, 1);
});

test('serve starts codex the way the desktop app does, on a token-protected loopback WebSocket', async (t) => {
  const home = tempHome(t);
  const port = await freePort();
  const argsFile = path.join(home, 'server-args.json');
  assert.equal(run(home, ['serve', '--port', String(port)], { FAKE_CODEX_ARGS_FILE: argsFile }).status, 0);
  const args = JSON.parse(fs.readFileSync(argsFile, 'utf8'));
  assert.deepEqual(args, [
    '-c', 'features.code_mode_host=true', 'app-server',
    '-c', 'plugins.codex-app-tools@openai-bundled.mcp_servers.codex_app.enabled=false',
    '--listen', `ws://127.0.0.1:${port}`,
    '--ws-auth', 'capability-token', '--ws-token-file', path.join(home, '.config/codex-app/ws-token'),
    '--analytics-default-enabled',
  ]);
});

test('serve replaces a registration left by a server that is gone', async (t) => {
  const home = tempHome(t);
  const port = await freePort();
  writeEndpoint(home, await freePort());
  const started = run(home, ['serve', '--port', String(port)]);
  assert.equal(started.status, 0, started.stderr);
  assert.equal(JSON.parse(fs.readFileSync(path.join(home, '.config/codex-app/server.json'), 'utf8')).port, port);
});

test('tui needs the shared server and passes the token and extra arguments to codex', async (t) => {
  const home = tempHome(t);
  const port = await freePort();
  assert.equal(run(home, ['tui']).status, 1, 'no server yet');
  assert.equal(run(home, ['serve', '--port', String(port)]).status, 0);
  const shown = run(home, ['tui', 'resume', '--last']);
  assert.equal(shown.status, 0, shown.stderr);
  assert.equal(shown.stdout.trim(),
    `fake-codex --remote ws://127.0.0.1:${port} --remote-auth-token-env CODEX_APP_WS_TOKEN resume --last`);
});

test('the bridge attaches to the shared server and relays lines both ways', async (t) => {
  const home = tempHome(t);
  const port = await freePort();
  assert.equal(run(home, ['serve', '--port', String(port)]).status, 0);
  const endpoint = path.join(home, '.config/codex-app/server.json');
  const result = await talk(['--endpoint', endpoint, '--codex', fakeCli(home), '--', 'app-server', '--analytics-default-enabled'], [request]);
  assert.deepEqual(result.out, [{ id: 1, result: { server: 'shared-ws', method: 'initialize' } }]);
  assert.match(result.err, /attached to the shared server/);
  assert.equal(result.code, 0);
});

// A bridge held open: resolves once it has said how it is connected.
function holdBridge(t, home, { port, rest = ['app-server', '--analytics-default-enabled'], env = {} } = {}) {
  const endpoint = path.join(home, '.config/codex-app/server.json');
  const child = childProcess.spawn(process.execPath, [bridgeScript, '--endpoint', endpoint, '--codex', fakeCli(home), '--', ...rest], {
    env: { ...process.env, CODEX_APP_SHARE_PORT: String(port), ...env },
  });
  t.after(() => child.kill('SIGTERM')); // lets it stop the server it started
  let err = '';
  const exited = new Promise((resolve) => child.on('exit', (code, signal) => resolve({ code, signal })));
  const connected = new Promise((resolve) => {
    child.stderr.on('data', (chunk) => {
      err += chunk;
      if (/started the shared server|attached to the shared server|starting codex itself/.test(err)) resolve(err);
    });
  });
  const ask = () => new Promise((resolve) => { child.stdout.once('data', (d) => resolve(JSON.parse(String(d)))); child.stdin.write(request + '\n'); });
  return { child, connected, exited, ask, endpoint, end: () => child.stdin.end() };
}

const registration = (home) => JSON.parse(fs.readFileSync(path.join(home, '.config/codex-app/server.json'), 'utf8'));
const portOpen = (port) => fetch(`http://127.0.0.1:${port}/readyz`).then((r) => r.status === 200, () => false);
async function until(check, what) {
  for (let i = 0; i < 100; i += 1) {
    if (await check()) return;
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  assert.fail('timed out waiting for ' + what);
}

test('the bridge starts the shared server itself when nothing is registered, and a terminal can use it', async (t) => {
  const home = tempHome(t);
  const port = await freePort();
  const argsFile = path.join(home, 'server-args.json');
  const bridge = holdBridge(t, home, { port, env: { FAKE_CODEX_ARGS_FILE: argsFile } });
  assert.match(await bridge.connected, new RegExp(`started the shared server on port ${port}`));
  assert.deepEqual(await bridge.ask(), { id: 1, result: { server: 'shared-ws', method: 'initialize' } });
  const info = registration(home);
  assert.equal(info.port, port);
  assert.equal(info.owner, 'app');
  assert.ok(info.pid > 0);
  assert.equal(fs.statSync(path.join(home, '.config/codex-app/ws-token')).mode & 0o077, 0, 'token is private');
  // The desktop's own arguments with the listener added after app-server.
  assert.deepEqual(JSON.parse(fs.readFileSync(argsFile, 'utf8')), [
    'app-server', '--listen', `ws://127.0.0.1:${port}`, '--ws-auth', 'capability-token',
    '--ws-token-file', path.join(home, '.config/codex-app/ws-token'), '--analytics-default-enabled',
  ]);
  // The terminal finds it: serve reports it, tui attaches, serve does not start a second one.
  assert.equal(run(home, ['serve', '--status']).status, 0);
  const again = run(home, ['serve']);
  assert.match(again.stdout, new RegExp(`serving at ws://127.0.0.1:${port} \\(pid ${info.pid}\\)`));
  assert.equal(run(home, ['tui']).stdout.trim().startsWith(`fake-codex --remote ws://127.0.0.1:${port}`), true);
});

test('the server the bridge started ends with it and takes its registration away', async (t) => {
  const home = tempHome(t);
  const port = await freePort();
  const bridge = holdBridge(t, home, { port });
  await bridge.connected;
  await bridge.ask();
  assert.equal(await portOpen(port), true);
  bridge.end();
  assert.equal((await bridge.exited).code, 0);
  await until(async () => !(await portOpen(port)), 'the server to stop');
  assert.equal(fs.existsSync(bridge.endpoint), false);
});

test('a terminated bridge takes the server it started with it', async (t) => {
  const home = tempHome(t);
  const port = await freePort();
  const bridge = holdBridge(t, home, { port });
  await bridge.connected;
  bridge.child.kill('SIGTERM');
  await bridge.exited;
  await until(async () => !(await portOpen(port)), 'the server to stop');
  assert.equal(fs.existsSync(bridge.endpoint), false);
});

// What the tray's quit does: the app process ends at once, so the bridge it started is killed
// without a chance to clean up, and the main process releases the server first.
test('the tray\'s quit releases the server the app started although the bridge is killed at once', async (t) => {
  const home = tempHome(t);
  const port = await freePort();
  const bridge = holdBridge(t, home, { port });
  await bridge.connected;
  await bridge.ask();
  assert.equal(await portOpen(port), true);
  const released = childProcess.spawnSync(process.execPath, ['-e', `
    const share = require(${JSON.stringify(path.join(__dirname, '..', 'app', 'owl-share.cjs'))});
    process.stdout.write(String(share.releaseAppServer(${JSON.stringify(bridge.endpoint)}, require('node:fs'))));
  `], { encoding: 'utf8' });
  assert.equal(released.stdout, 'true');
  bridge.child.kill('SIGKILL');
  await bridge.exited;
  await until(async () => !(await portOpen(port)), 'the server to stop');
  assert.equal(fs.existsSync(bridge.endpoint), false, 'no stale registration is left');
});

test('without the release a killed bridge leaves a stale registration (what the tray\'s quit used to do)', async (t) => {
  const home = tempHome(t);
  const port = await freePort();
  const bridge = holdBridge(t, home, { port });
  await bridge.connected;
  const pid = registration(home).pid;
  bridge.child.kill('SIGKILL');
  await bridge.exited;
  assert.equal(fs.existsSync(bridge.endpoint), true);
  try { process.kill(pid, 'SIGTERM'); } catch { /* already gone */ }
  await until(async () => !(await portOpen(port)), 'the orphan to stop');
});

test('a second bridge attaches to the running server and leaves it running when it ends', async (t) => {
  const home = tempHome(t);
  const port = await freePort();
  const first = holdBridge(t, home, { port });
  await first.connected;
  const second = holdBridge(t, home, { port });
  assert.match(await second.connected, /attached to the shared server/);
  assert.equal((await second.ask()).result.server, 'shared-ws');
  second.end();
  assert.equal((await second.exited).code, 0);
  assert.equal(await portOpen(port), true, 'still up for the first');
  assert.equal(registration(home).owner, 'app');
});

test('a bridge does not stop a server a terminal started', async (t) => {
  const home = tempHome(t);
  const port = await freePort();
  assert.equal(run(home, ['serve', '--port', String(port)]).status, 0);
  const bridge = holdBridge(t, home, { port: await freePort() });
  assert.match(await bridge.connected, /attached/);
  bridge.end();
  await bridge.exited;
  assert.equal(await portOpen(port), true);
  assert.equal(registration(home).port, port);
  assert.notEqual(registration(home).owner, 'app');
});

test('stopping the server from the terminal makes the bridge exit so the app starts it again', async (t) => {
  const home = tempHome(t);
  const port = await freePort();
  const bridge = holdBridge(t, home, { port });
  await bridge.connected;
  await bridge.ask();
  assert.equal(run(home, ['serve', '--stop']).status, 0);
  assert.notEqual((await bridge.exited).code, 0);
});

test('a registration left by a server that is gone is replaced by a new one', async (t) => {
  const home = tempHome(t);
  const port = await freePort();
  writeEndpoint(home, await freePort());
  const bridge = holdBridge(t, home, { port });
  assert.match(await bridge.connected, /started the shared server/);
  assert.equal(registration(home).port, port);
  assert.equal(registration(home).owner, 'app');
});

test('the bridge starts on another port when the usual one is taken', async (t) => {
  const home = tempHome(t);
  const taken = net.createServer();
  const port = await new Promise((resolve) => taken.listen(0, '127.0.0.1', () => resolve(taken.address().port)));
  t.after(() => taken.close());
  const bridge = holdBridge(t, home, { port });
  assert.match(await bridge.connected, /started the shared server/);
  assert.notEqual(registration(home).port, port);
  assert.equal((await bridge.ask()).result.server, 'shared-ws');
});

test('the bridge starts codex itself only when no shared server can be started', async (t) => {
  const home = tempHome(t);
  const bridge = holdBridge(t, home, { port: await freePort(), env: { FAKE_CODEX_NO_LISTEN: '1' } });
  assert.match(await bridge.connected, /no shared server could be started; starting codex itself/);
  assert.deepEqual(await bridge.ask(), { id: 1, result: { server: 'own-stdio', method: 'initialize' } });
  assert.equal(fs.existsSync(bridge.endpoint), false);
});

test('the bridge starts its own server when the endpoint file or the token is missing', async (t) => {
  const home = tempHome(t);
  const first = holdBridge(t, home, { port: await freePort() });
  await first.connected;
  assert.equal((await first.ask()).result.server, 'shared-ws');
  first.end();
  await first.exited;
  const endpoint = writeEndpoint(home, await freePort());
  fs.rmSync(path.join(home, '.config/codex-app/ws-token'));
  const second = holdBridge(t, home, { port: await freePort() });
  await second.connected;
  assert.equal((await second.ask()).result.server, 'shared-ws');
  assert.equal(fs.existsSync(endpoint), true);
});

test('the bridge starts its own server when the registered one refuses the token', async (t) => {
  const home = tempHome(t);
  const port = await freePort();
  assert.equal(run(home, ['serve', '--port', String(port)]).status, 0);
  // The new registration replaces this one, so stop the first server by hand.
  const original = registration(home).pid;
  t.after(() => { try { process.kill(original); } catch { /* already gone */ } });
  fs.writeFileSync(path.join(home, '.config/codex-app/ws-token'), 'a-different-token\n');
  const bridge = holdBridge(t, home, { port: await freePort() });
  assert.match(await bridge.connected, /started the shared server/);
  assert.equal((await bridge.ask()).result.server, 'shared-ws');
});

test('the bridge exits non-zero when the shared server goes away', async (t) => {
  const home = tempHome(t);
  const port = await freePort();
  assert.equal(run(home, ['serve', '--port', String(port)]).status, 0);
  const endpoint = path.join(home, '.config/codex-app/server.json');
  const child = childProcess.spawn(process.execPath, [bridgeScript, '--endpoint', endpoint, '--codex', fakeCli(home), '--', 'app-server']);
  await new Promise((resolve) => { child.stdout.once('data', resolve); child.stdin.write(request + '\n'); });
  const exited = new Promise((resolve) => child.on('exit', (code) => resolve(code)));
  assert.equal(run(home, ['serve', '--stop']).status, 0);
  assert.notEqual(await exited, 0);
});

// The real shim file in a scratch app dir, with a host config pointing at the fake codex.
function shimDir(t, home) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'codex-shim-'));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  for (const name of ['owl-host-shim.cjs', 'owl-share.cjs', 'owl-codex-bridge.cjs']) {
    fs.copyFileSync(path.join(__dirname, '..', 'app', name), path.join(dir, name));
  }
  fs.writeFileSync(path.join(dir, 'chatgpt-host-config.json'), JSON.stringify({
    home, codexCli: fakeCli(home), codexHome: path.join(home, '.codex'), path: process.env.PATH, nodeCli: process.execPath,
  }));
  return dir;
}

// What the app does: spawn `codex <args>` after the shim is loaded; send one request, read one reply.
function appSpawn(dir, args) {
  const driver = `
    require(${JSON.stringify(path.join(dir, 'owl-host-shim.cjs'))});
    const child = require('node:child_process').spawn('codex', ${JSON.stringify(args)});
    let out = '';
    child.stdout.on('data', (d) => { out += d; });
    child.stdin.write(${JSON.stringify(request)} + '\\n');
    setTimeout(() => { child.stdin.end(); }, 1200);
    child.on('exit', () => { process.stdout.write('\\n@@RESULT@@' + out); process.exit(0); });
    setTimeout(() => { child.kill(); }, 8000);
  `;
  const result = childProcess.spawnSync(process.execPath, ['-e', driver], { encoding: 'utf8', timeout: 30000 });
  const [log, reply] = result.stdout.split('@@RESULT@@');
  return { log, reply: (reply || '').trim() };
}

const desktopArgs = ['-c', 'features.code_mode_host=true', 'app-server', '--analytics-default-enabled'];

test('the shim sends the app-server spawn through the bridge to the shared server', async (t) => {
  const home = tempHome(t);
  const port = await freePort();
  assert.equal(run(home, ['serve', '--port', String(port)]).status, 0);
  const { log, reply } = appSpawn(shimDir(t, home), desktopArgs);
  assert.deepEqual(JSON.parse(reply), { id: 1, result: { server: 'shared-ws', method: 'initialize' } });
  assert.match(log, /OWL_SHARE app-server spawn goes through the bridge/);
});

test('the shim sends the app-server spawn through the bridge even when no server runs, and the bridge starts one', async (t) => {
  const home = tempHome(t);
  const port = await freePort();
  process.env.CODEX_APP_SHARE_PORT = String(port);
  t.after(() => { delete process.env.CODEX_APP_SHARE_PORT; });
  const { log, reply } = appSpawn(shimDir(t, home), desktopArgs);
  assert.deepEqual(JSON.parse(reply), { id: 1, result: { server: 'shared-ws', method: 'initialize' } });
  assert.match(log, /OWL_SHARE app-server spawn goes through the bridge/);
});

test('the shim leaves other codex invocations alone even when a shared server runs', async (t) => {
  const home = tempHome(t);
  const port = await freePort();
  assert.equal(run(home, ['serve', '--port', String(port)]).status, 0);
  const { log, reply } = appSpawn(shimDir(t, home), ['--version']);
  assert.equal(reply, 'fake-codex --version');
  assert.doesNotMatch(log, /OWL_SHARE/);
});

test('help lists the shared server commands', (t) => {
  const home = tempHome(t);
  const help = run(home, ['--help']);
  assert.equal(help.status, 0);
  assert.match(help.stdout, /serve\s+Start the shared codex app-server/);
  assert.match(help.stdout, /tui\s+Open the Codex terminal UI/);
});
