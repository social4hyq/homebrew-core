// Antigravity OHOS shell: starts the official language server and loads its
// loopback UI. The vendor engine is closed source; this file is tap-authored.
const { app, BrowserWindow, session } = require('electron');
const { spawn } = require('child_process');
const path = require('path');
const crypto = require('crypto');
const fs = require('fs');

const PORT_RE = /listening on \w+ port at (\d+) for HTTP(S)?\b/i;
const HAP_ROOT = path.join(__dirname, '..', '..', '..', '..');
// bm reports nativeLibraryPath=libs/arm64; the v8a HAP entry is deployed there at runtime.
const LS_BIN = path.join(HAP_ROOT, 'libs', 'arm64', 'antigravity-language-server.bin');
const VERSION = '2.34.0';

let server = null;
let pollTimer = null;

// OHOS Electron exposes appData as an unsupported path; map it to the app's
// private userData directory before Chromium initialises (same as the other
// Electron HAPs in this tap). The adapter already passes --no-sandbox.
const privateDataBase = app.getPath('userData');
if (typeof privateDataBase !== 'string' || !path.isAbsolute(privateDataBase)) {
  throw new Error('Electron did not provide a private userData path');
}
fs.mkdirSync(privateDataBase, { recursive: true, mode: 0o700 });
app.setPath('appData', privateDataBase);

function dataDir() {
  const dir = path.join(privateDataBase, 'antigravity');
  fs.mkdirSync(dir, { recursive: true });
  return dir;
}

function writeLog(line) {
  try {
    fs.appendFileSync(path.join(dataDir(), 'shell.log'), `${new Date().toISOString()} ${line}\n`);
  } catch (_) {
    // Logging must never prevent startup.
  }
}

function startServer() {
  if (!fs.existsSync(LS_BIN)) {
    writeLog(`language server missing: ${LS_BIN}`);
    return Promise.reject(new Error('language server missing'));
  }
  const csrf = crypto.randomBytes(32).toString('hex');
  const args = [
    '--standalone',
    '--override_ide_name', 'antigravity',
    '--subclient_type', 'hub',
    '--override_ide_version', VERSION,
    '--override_user_agent_name', 'antigravity',
    '--https_server_port', '0',
    '--csrf_token', csrf,
    '--app_data_dir', dataDir(),
    '--api_server_url', 'https://generativelanguage.googleapis.com',
    '--cloud_code_endpoint', 'https://daily-cloudcode-pa.googleapis.com',
    '--enable_sidecars',
  ];
  const env = {
    ...process.env,
    ANTIGRAVITY_SERVER_CSRF_TOKEN: csrf,
    AGY_REQUIRE_AUTHENTICATED_UI_BOOTSTRAP: '1',
  };
  writeLog(`spawning language server with ${args.length} args`);
  server = spawn(LS_BIN, args, { stdio: ['pipe', 'pipe', 'pipe'], env });
  server.stdout.on('data', (chunk) => writeLog(`ls-out: ${String(chunk).trim()}`));

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
      writeLog(`ls-err: ${text.trim()}`);
      buffer += text;
      const match = buffer.match(PORT_RE);
      if (match) finish(resolve, Number(match[1]));
      if (buffer.length > 1 << 20) buffer = buffer.slice(-(1 << 16));
    });
    server.on('error', (error) => finish(reject, error));
    server.on('exit', (code) => finish(reject, new Error(`language server exited: ${code}`)));
  });
}

function openWindow(port) {
  session.defaultSession.setCertificateVerifyProc((request, callback) => {
    const host = new URL(request.url).hostname;
    callback(host === '127.0.0.1' || host === 'localhost' ? 0 : -3);
  });
  const win = new BrowserWindow({
    width: 1440,
    height: 900,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      webviewTag: true,
    },
  });
  win.loadURL(`https://127.0.0.1:${port}/`);
  return win;
}

app.whenReady().then(async () => {
  try {
    const port = await startServer();
    writeLog(`language server listening on ${port}`);
    openWindow(port);
  } catch (error) {
    writeLog(`startup failed: ${error && error.message ? error.message : error}`);
    app.exit(2);
  }
});

app.on('before-quit', () => {
  if (pollTimer) clearTimeout(pollTimer);
  if (server && !server.killed) server.kill();
});
