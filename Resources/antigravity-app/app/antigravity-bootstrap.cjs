// Antigravity OHOS shell: spawns the official language server on the HOST and
// loads its loopback UI. The HAP sandbox cannot exec a binary under libs/, so
// the engine is installed to a stable host path by `antigravity-app install`;
// this shell reads that path from the injected host config.
const { app, BrowserWindow, session } = require('electron');
const { spawn } = require('child_process');
const path = require('path');
const crypto = require('crypto');
const fs = require('fs');

const PORT_RE = /listening on \w+ port at (\d+) for HTTP(S)?\b/i;
const VERSION = '2.34.0';
const CONFIG = path.join(__dirname, 'antigravity-host-config.json');

let server = null;

console.log('AGY shell: bootstrap entered');
const cfg = JSON.parse(fs.readFileSync(CONFIG, 'utf8'));
const absolute = (name, value) => {
  if (typeof value !== 'string' || !path.isAbsolute(value)) {
    throw new Error(`invalid host config: ${name}`);
  }
  return value;
};
const hostHome = absolute('home', cfg.home);
const engine = absolute('engine', cfg.engine);
console.log('AGY shell: engine=' + engine + ' exists=' + fs.existsSync(engine));

const privateDataBase = app.getPath('userData');
if (typeof privateDataBase !== 'string' || !path.isAbsolute(privateDataBase)) {
  throw new Error('Electron did not provide a private userData path');
}
fs.mkdirSync(privateDataBase, { recursive: true, mode: 0o700 });
app.setPath('appData', privateDataBase);

function dlog(line) { console.log('AGY shell: ' + line); }

function startServer() {
  if (!fs.existsSync(engine)) {
    return Promise.reject(new Error('language server missing: ' + engine));
  }
  const csrf = crypto.randomBytes(32).toString('hex');
  // The language server requires a path RELATIVE to its HOME (hostHome); an
  // absolute path makes it abort with "must not be absolute".
  const dir = '.antigravity/desktop';
  const args = [
    '--standalone',
    '--override_ide_name', 'antigravity',
    '--subclient_type', 'hub',
    '--override_ide_version', VERSION,
    '--override_user_agent_name', 'antigravity',
    '--https_server_port', '0',
    '--csrf_token', csrf,
    '--app_data_dir', dir,
    '--api_server_url', 'https://generativelanguage.googleapis.com',
    '--cloud_code_endpoint', 'https://daily-cloudcode-pa.googleapis.com',
    '--enable_sidecars',
  ];
  // The spawned engine must see the host environment, not the HAP sandbox.
  const env = {
    ...process.env,
    HOME: hostHome,
    PATH: cfg.path || process.env.PATH,
    ANTIGRAVITY_SERVER_CSRF_TOKEN: csrf,
    AGY_REQUIRE_AUTHENTICATED_UI_BOOTSTRAP: '1',
  };
  dlog('spawning host engine');
  server = spawn(engine, args, { stdio: ['pipe', 'pipe', 'pipe'], env });
  dlog('spawned pid=' + server.pid);
  server.stdout.on('data', (chunk) => dlog('ls-out: ' + String(chunk).trim().slice(0, 300)));
  server.on('error', (error) => dlog('spawn error: ' + error.message));
  server.on('exit', (code) => dlog('ls exit: ' + code));

  return new Promise((resolve, reject) => {
    let buffer = '';
    let settled = false;
    const finish = (fn, value) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      fn(value);
    };
    const timer = setTimeout(() => finish(reject, new Error('language server start timeout')), 120000);
    server.stderr.on('data', (chunk) => {
      const text = String(chunk);
      dlog('ls-err: ' + text.trim().slice(0, 300));
      buffer += text;
      const match = buffer.match(PORT_RE);
      if (match) finish(resolve, Number(match[1]));
      if (buffer.length > 1 << 20) buffer = buffer.slice(-(1 << 16));
    });
  });
}

function openWindow(port) {
  session.defaultSession.setCertificateVerifyProc((request, callback) => {
    let host = '';
    try { host = new URL(request.url).hostname; } catch (_) { /* ignore */ }
    callback(host === '127.0.0.1' || host === 'localhost' ? 0 : -3);
  });
  const win = new BrowserWindow({
    width: 1440,
    height: 900,
    webPreferences: { nodeIntegration: false, contextIsolation: true, webviewTag: true },
  });
  win.loadURL(`https://127.0.0.1:${port}/`);
  dlog('loaded window at port ' + port);
  return win;
}

app.whenReady().then(async () => {
  try {
    const port = await startServer();
    openWindow(port);
  } catch (error) {
    dlog('startup failed: ' + (error && error.message ? error.message : error));
    app.exit(2);
  }
});

app.on('before-quit', () => {
  if (server && !server.killed) server.kill();
});
