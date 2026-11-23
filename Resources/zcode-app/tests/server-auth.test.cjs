'use strict';

// Isolated tests for the service token: the shell-side helpers, and the real
// zcode-desktop.sh against fake services on loopback with a temporary HOME. No
// real zcode, bun or device state is touched.

const assert = require('node:assert/strict');
const { spawn, spawnSync } = require('node:child_process');
const fs = require('node:fs');
const http = require('node:http');
const net = require('node:net');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');

const auth = require('../app/server-auth.cjs');

const SCRIPT = path.join(__dirname, '..', 'scripts', 'zcode-desktop.sh');
const MAIN = path.join(__dirname, '..', 'app', 'main.cjs');
const TOKEN = 'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90';

test('derives the token file from the install-time HOME, then the environment', () => {
  const suffix = path.join('.zcode', 'v2', 'desktop-token');
  assert.equal(auth.tokenFile({ home: '/h' }, { HOME: '/sandbox' }), path.join('/h', suffix));
  assert.equal(auth.tokenFile({}, { HOME: '/sandbox' }), path.join('/sandbox', suffix));
  assert.equal(auth.tokenFile(undefined, {}), '');
  assert.equal(auth.tokenFile({ home: '/h' }, { ZCODE_DESKTOP_TOKEN_FILE: '/x/t' }), '/x/t');
});

test('reads a plain token and treats anything else as no token', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'zcode-token-'));
  try {
    const file = path.join(dir, 'desktop-token');
    assert.equal(auth.readToken(fs, file), '');
    fs.writeFileSync(file, TOKEN + '\n');
    assert.equal(auth.readToken(fs, file), TOKEN);
    fs.writeFileSync(file, '');
    assert.equal(auth.readToken(fs, file), '');
    fs.writeFileSync(file, 'short');
    assert.equal(auth.readToken(fs, file), '');
    fs.writeFileSync(file, 'has space in the middle of it 1234567890');
    assert.equal(auth.readToken(fs, file), '');
    assert.equal(auth.readToken(fs, ''), '');
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

test('sends the token as a Bearer header and only in the first page URL', () => {
  assert.deepEqual(auth.infoHeaders(TOKEN), { Authorization: `Bearer ${TOKEN}` });
  assert.deepEqual(auth.infoHeaders(''), {});
  assert.equal(auth.authedUrl('http://127.0.0.1:1', TOKEN), `http://127.0.0.1:1/?token=${TOKEN}`);
  assert.equal(auth.authedUrl('http://127.0.0.1:1', ''), 'http://127.0.0.1:1/');
  assert.equal(auth.authedUrl('http://127.0.0.1:1', 'a b&c'), 'http://127.0.0.1:1/?token=a%20b%26c');
});

test('accepts only a 200 that says authentication is required', () => {
  assert.equal(auth.acceptServerInfo(200, '{"authRequired":true,"version":"1"}'), true);
  assert.equal(auth.acceptServerInfo(200, '{"authRequired":false}'), false);
  assert.equal(auth.acceptServerInfo(200, '{"version":"1"}'), false);
  assert.equal(auth.acceptServerInfo(200, 'not json'), false);
  assert.equal(auth.acceptServerInfo(200, ''), false);
  assert.equal(auth.acceptServerInfo(401, '{"authRequired":true}'), false);
});

test('the shell probes with the token header and loads the page through the token URL', () => {
  const source = fs.readFileSync(MAIN, 'utf8');
  assert.match(source, /headers: serverAuth\.infoHeaders\(token\)/);
  assert.match(source, /loadURL\(serverAuth\.authedUrl\(origin, currentToken\(\)\)\)/);
  assert.doesNotMatch(source, /loadURL\(origin \+ '\/'\)/);
});

// --- zcode-desktop.sh against fake services -------------------------------

const FAKE_SERVER = `'use strict';
const http = require('node:http');
const token = process.env.ZCODE_SERVER_AUTH_TOKEN || '';
const port = Number(process.env.PORT || process.env.FAKE_PORT);
http.createServer((req, res) => {
  if (token && req.url.startsWith('/api/') && req.headers.authorization !== 'Bearer ' + token) {
    res.statusCode = 401;
    res.end('{"error":"Unauthorized"}');
    return;
  }
  res.setHeader('content-type', 'application/json');
  res.end(JSON.stringify({ version: '9.9.9', authRequired: Boolean(token) }));
}).on('error', (error) => { console.log('fake server error ' + error.code); process.exit(1); })
  .listen(port, '127.0.0.1', () => console.log('fake server listening ' + port + ' token=' + Boolean(token)));
`;

function freePort() {
  return new Promise((resolve) => {
    const server = net.createServer();
    server.listen(0, '127.0.0.1', () => {
      const { port } = server.address();
      server.close(() => resolve(port));
    });
  });
}

function sandbox(port) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'zcode-script-'));
  const home = path.join(root, 'home');
  const config = path.join(root, 'config');
  fs.mkdirSync(home, { recursive: true });
  fs.mkdirSync(config, { recursive: true });
  fs.writeFileSync(path.join(config, 'config.json'), JSON.stringify({ port, workspace: home }));
  const server = path.join(root, 'fake-server.cjs');
  fs.writeFileSync(server, FAKE_SERVER);
  // Fallback path: `zcode --web --port N` is a node script that reads the token
  // from the environment like the real one.
  const zcode = path.join(root, 'zcode');
  // Absolute node: the test environment of brew has a minimal PATH.
  fs.writeFileSync(zcode, `#!/bin/sh\nexec ${process.execPath} ${server}\n`, { mode: 0o755 });
  // Primary path: a fake bun that accepts the patch step and runs the entry.
  const bun = path.join(root, 'bun');
  fs.writeFileSync(bun, `#!/bin/sh\nif [ "$1" = "-e" ]; then exit 0; fi\nexec ${process.execPath} "$@"\n`, { mode: 0o755 });
  const zroot = path.join(root, 'zroot');
  fs.mkdirSync(path.join(zroot, 'server'), { recursive: true });
  fs.mkdirSync(path.join(zroot, 'agent'), { recursive: true });
  fs.writeFileSync(path.join(zroot, 'server', 'entry-http.js'), FAKE_SERVER);
  fs.writeFileSync(path.join(zroot, 'agent', 'zcode.cjs'), '');
  // Under `brew test` the first curl on PATH is Homebrew's shim, which refuses to
  // run without the HOMEBREW_* variables of the calling brew; keep them (and the
  // certificate setting) so the script's curl behaves as it does in that run.
  const inherited = {};
  for (const [key, value] of Object.entries(process.env)) {
    if (key.startsWith('HOMEBREW_') || key === 'SSL_CERT_FILE') inherited[key] = value;
  }
  const env = {
    ...inherited,
    PATH: process.env.PATH,
    HOME: home,
    FAKE_PORT: String(port),
    ZCODE_DESKTOP_CONFIG_DIR: config,
    ZCODE_DESKTOP_ZCODE: zcode,
    ZCODE_DESKTOP_BUN: bun,
  };
  return { root, home, config, env, zroot, tokenFile: path.join(home, '.zcode', 'v2', 'desktop-token') };
}

// Asynchronous on purpose: some tests serve from this very process, which must
// keep answering while the script runs.
function run(sb, args, extraEnv = {}) {
  return new Promise((resolve) => {
    const child = spawn('bash', [SCRIPT, ...args], { env: { ...sb.env, ...extraEnv } });
    let stdout = '';
    let stderr = '';
    child.stdout.on('data', (chunk) => { stdout += chunk; });
    child.stderr.on('data', (chunk) => { stderr += chunk; });
    const timer = setTimeout(() => child.kill('SIGKILL'), 90000);
    child.on('close', (status) => {
      clearTimeout(timer);
      resolve({ status, stdout, stderr });
    });
  });
}

// One request on its own connection, so a service that was replaced or stopped
// never answers through a kept-alive socket.
function info(port, token) {
  return new Promise((resolve) => {
    const req = http.get({
      host: '127.0.0.1', port, path: '/api/server-info', agent: false,
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    }, (res) => {
      let body = '';
      res.on('data', (chunk) => { body += chunk; });
      res.on('end', () => {
        let json = null;
        try { json = JSON.parse(body); } catch {}
        resolve({ status: res.statusCode, json });
      });
    });
    req.on('error', () => resolve(null));
  });
}

function listen(port, handler) {
  return new Promise((resolve) => {
    const server = http.createServer(handler);
    server.listen(port, '127.0.0.1', () => resolve(server));
  });
}

function reply(res, body, status = 200) {
  res.statusCode = status;
  res.setHeader('content-type', 'application/json');
  res.end(JSON.stringify(body));
}

function stopManaged(sb) {
  try {
    const pid = Number(fs.readFileSync(path.join(sb.config, 'web.pid'), 'utf8'));
    if (pid > 1) process.kill(pid);
  } catch {}
}

function cleanup(sb) {
  stopManaged(sb);
  fs.rmSync(sb.root, { recursive: true, force: true });
}

test('status does not create the token and reports an unhealthy service without one', async () => {
  const port = await freePort();
  const sb = sandbox(port);
  try {
    const result = await run(sb, ['status']);
    assert.equal(result.status, 1);
    // Only the verdict: a missing token file must not leak a shell error line.
    assert.equal(result.stderr, `zcode-desktop: server not healthy at http://127.0.0.1:${port}\n`);
    assert.equal(result.stdout, '');
    assert.equal(fs.existsSync(sb.tokenFile), false);
  } finally {
    cleanup(sb);
  }
});

test('status sends the Bearer header and only accepts a protected service', async () => {
  const port = await freePort();
  const sb = sandbox(port);
  fs.mkdirSync(path.dirname(sb.tokenFile), { recursive: true });
  fs.writeFileSync(sb.tokenFile, TOKEN);
  const seen = [];
  let mode = 'protected';
  const server = await listen(port, (req, res) => {
    seen.push(req.headers.authorization || '');
    if (mode === 'open') return reply(res, { version: '1.2.3', authRequired: false });
    if (req.headers.authorization !== `Bearer ${TOKEN}`) return reply(res, { error: 'Unauthorized' }, 401);
    return reply(res, { version: '1.2.3', authRequired: true });
  });
  try {
    const good = await run(sb, ['status']);
    assert.equal(good.status, 0, good.stderr);
    assert.match(good.stdout, /healthy at http:\/\/127\.0\.0\.1:\d+ \(zcode 1\.2\.3\)/);
    // The health check and the version lookup each send the header.
    assert.ok(seen.length >= 1);
    assert.ok(seen.every((value) => value === `Bearer ${TOKEN}`));

    fs.writeFileSync(sb.tokenFile, TOKEN.replace(/^a/, 'b'));
    const wrong = await run(sb, ['status']);
    assert.equal(wrong.status, 1);
    assert.match(wrong.stderr, /not healthy/);

    // An older server answers 200 but does not require authentication.
    fs.writeFileSync(sb.tokenFile, TOKEN);
    mode = 'open';
    const open = await run(sb, ['status']);
    assert.equal(open.status, 1);
    assert.match(open.stderr, /not healthy/);
  } finally {
    server.close();
    cleanup(sb);
  }
});

test('the token never appears in the arguments of the probe', async () => {
  const port = await freePort();
  const sb = sandbox(port);
  fs.mkdirSync(path.dirname(sb.tokenFile), { recursive: true });
  fs.writeFileSync(sb.tokenFile, TOKEN);
  // A curl stand-in that records its arguments and answers like a protected service.
  const bin = path.join(sb.root, 'bin');
  fs.mkdirSync(bin);
  const log = path.join(sb.root, 'curl-args');
  fs.writeFileSync(path.join(bin, 'curl'),
    `#!/bin/sh\nprintf '%s\\n' "$*" >> ${log}\ncat >/dev/null\nprintf '{"version":"1","authRequired":true}\\n200'\n`,
    { mode: 0o755 });
  try {
    const result = await run(sb, ['status'], { PATH: `${bin}:${process.env.PATH}` });
    assert.equal(result.status, 0, result.stderr);
    const args = fs.readFileSync(log, 'utf8');
    assert.ok(args.length > 0);
    assert.equal(args.includes(TOKEN), false);
  } finally {
    cleanup(sb);
  }
});

for (const variant of ['bundled server', 'zcode --web fallback']) {
  test(`serve creates a 0600-style token and starts the ${variant} with it`, async () => {
    const port = await freePort();
    const sb = sandbox(port);
    const extra = variant === 'bundled server' ? { ZCODE_DESKTOP_ZCODE_ROOT: sb.zroot } : {};
    try {
      assert.equal(fs.existsSync(sb.tokenFile), false);
      const result = await run(sb, ['serve'], extra);
      assert.equal(result.status, 0, result.stderr + result.stdout);
      assert.match(result.stderr, /generated service token/);
      assert.match(result.stdout, /serving at http:\/\/127\.0\.0\.1:\d+/);
      const token = fs.readFileSync(sb.tokenFile, 'utf8');
      assert.match(token, /^[0-9a-f]{64}$/);
      // Not readable by others (hmdfs keeps group bits, so only "other" is checked).
      assert.equal(fs.statSync(sb.tokenFile).mode & 0o007, 0);

      // The service really enforces the token the wrapper handed it.
      assert.equal((await info(port)).status, 401);
      const withToken = await info(port, token);
      assert.equal(withToken.status, 200);
      assert.equal(withToken.json.authRequired, true);

      // A second serve reuses it and keeps the same token.
      const again = await run(sb, ['serve'], extra);
      assert.equal(again.status, 0, again.stderr);
      assert.match(again.stdout, /already healthy/);
      assert.equal(fs.readFileSync(sb.tokenFile, 'utf8'), token);
    } finally {
      cleanup(sb);
    }
  });
}

test('serve refuses to reuse an older service that has no authentication', async () => {
  const port = await freePort();
  const sb = sandbox(port);
  const server = await listen(port, (req, res) => reply(res, { version: '1', authRequired: false }));
  try {
    const result = await run(sb, ['serve']);
    assert.equal(result.status, 1);
    assert.match(result.stderr, /without authentication/);
    assert.doesNotMatch(result.stdout, /already healthy/);
  } finally {
    server.close();
    cleanup(sb);
  }
});

test('serve replaces its own older unauthenticated service', async () => {
  const port = await freePort();
  const sb = sandbox(port);
  // The managed server of an older version: same user, listed in the pid file.
  // A child of this test, so a container without an init still reaps it once
  // the script has stopped it (an unreaped zombie would keep looking alive).
  const oldServer = spawn(process.execPath, [path.join(sb.root, 'fake-server.cjs')], {
    env: { ...sb.env, FAKE_PORT: String(port) },
    stdio: 'ignore',
  });
  const pid = oldServer.pid;
  fs.writeFileSync(path.join(sb.config, 'web.pid'), String(pid));
  try {
    for (let i = 0; i < 40 && !(await info(port)); i++) await new Promise((r) => setTimeout(r, 100));
    assert.equal((await info(port)).json.authRequired, false);
    const result = await run(sb, ['serve']);
    // One line: brew keeps only the last lines of a failing test's log.
    let serverLog = '';
    try { serverLog = fs.readFileSync(path.join(sb.config, 'web.log'), 'utf8').slice(-600); } catch {}
    const output = JSON.stringify({
      status: result.status, stderr: result.stderr, serverLog,
      oldExit: [oldServer.exitCode, oldServer.signalCode],
    }).slice(0, 2500);
    assert.equal(result.status, 0, output);
    assert.match(result.stderr, /stale server process/, output);
    assert.match(result.stdout, /serving at/, output);
    const token = fs.readFileSync(sb.tokenFile, 'utf8');
    assert.equal((await info(port, token)).json.authRequired, true);
    assert.equal((await info(port)).status, 401);
  } finally {
    try { oldServer.kill(); } catch {}
    cleanup(sb);
  }
});
