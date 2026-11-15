'use strict';
// OpenCode desktop shell for OpenHarmony.
// Loads a local `opencode serve` instance and injects HTTP basic auth for its
// origin. Connection parameters and the host environment needed to spawn the
// server are baked into config.json by `opencode-desktop install` before HAP
// signing. On launch the shell starts the server itself when it is not
// already running (requires the CUSTOM_SANDBOX / READ_WRITE_USER_FILE ACLs).
const { app, BrowserWindow } = require('electron');
const { spawn } = require('node:child_process');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');

let config = { port: 0, password: '' };
try {
  Object.assign(config, JSON.parse(fs.readFileSync(path.join(__dirname, 'config.json'), 'utf8')));
} catch (error) {
  console.error('OPENCODE_DESKTOP config unreadable: ' + String(error));
}
const configured = Number.isInteger(config.port) && config.port > 0 && typeof config.password === 'string' && config.password.length > 0;
const origin = configured ? `http://127.0.0.1:${config.port}` : null;
const authHeader = configured ? 'Basic ' + Buffer.from(`opencode:${config.password}`, 'utf8').toString('base64') : null;
const canAutoStart = configured && typeof config.opencode === 'string' && config.opencode.length > 0;

let serveChild = null;
let serveSpawnError = '';

function serverUp(timeoutMs) {
  return new Promise((resolve) => {
    if (!configured) return resolve(false);
    const req = http.get({
      host: '127.0.0.1', port: config.port, path: '/api/config',
      headers: { Authorization: authHeader }, timeout: timeoutMs, agent: false,
    }, (res) => {
      res.resume();
      resolve(res.statusCode === 200);
    });
    req.on('timeout', () => { req.destroy(); resolve(false); });
    req.on('error', () => resolve(false));
  });
}

function serveLogPath() {
  const home = config.host && config.host.home;
  if (typeof home === 'string' && home.length > 0) {
    try {
      const dir = path.join(home, '.cache', 'opencode-desktop');
      fs.mkdirSync(dir, { recursive: true });
      return path.join(dir, 'serve.log');
    } catch (error) {
      console.error('OPENCODE_DESKTOP host log dir unavailable: ' + String(error));
    }
  }
  return path.join(app.getPath('userData'), 'opencode-serve.log');
}

function spawnServer() {
  if (!canAutoStart || serveChild) return;
  const host = config.host && typeof config.host === 'object' ? config.host : {};
  const env = Object.assign({}, process.env);
  // The child runs in the app sandbox with the weak-sandbox ACLs: host paths
  // are reachable, but HOME/XDG must point at the real host values so the
  // server shares the TUI's database and configuration.
  if (typeof host.home === 'string') env.HOME = host.home;
  if (typeof host.path === 'string') env.PATH = host.path;
  // An empty value means "the host did not define it"; drop the sandbox's
  // inherited value instead of pointing the server at a sandbox path.
  for (const [key, envKey] of [['xdgConfig', 'XDG_CONFIG_HOME'], ['xdgData', 'XDG_DATA_HOME'], ['xdgState', 'XDG_STATE_HOME']]) {
    if (typeof host[key] !== 'string') continue;
    if (host[key]) env[envKey] = host[key];
    else delete env[envKey];
  }
  env.OPENCODE_SERVER_PASSWORD = config.password;
  // Temp files must stay inside the sandbox; the host TMPDIR may be denied.
  env.TMPDIR = app.getPath('temp');

  let logFd;
  const logPath = serveLogPath();
  try {
    logFd = fs.openSync(logPath, 'a');
    fs.writeSync(logFd, `\n[shell] ${new Date().toISOString()} spawn ${config.opencode} serve ` +
      `HOME=${env.HOME} TMPDIR=${env.TMPDIR} XDG_CONFIG_HOME=${env.XDG_CONFIG_HOME === undefined ? '<unset>' : env.XDG_CONFIG_HOME}\n`);
  } catch (error) {
    console.error('OPENCODE_DESKTOP cannot open serve log: ' + String(error));
    logFd = undefined;
  }
  try {
    serveChild = spawn(config.opencode, ['serve', '--hostname', '127.0.0.1', '--port', String(config.port)], {
      env,
      // The server's config watcher follows the cwd; spawning with cwd "/"
      // makes it watch / and the sandbox denies access('/'), turning
      // /api/config into a 500. Anchor it on the host home instead.
      cwd: typeof host.home === 'string' && host.home.length > 0 ? host.home : undefined,
      stdio: ['ignore', logFd === undefined ? 'ignore' : logFd, logFd === undefined ? 'ignore' : logFd],
    });
  } catch (error) {
    serveSpawnError = String(error);
    console.error('OPENCODE_DESKTOP spawn failed: ' + serveSpawnError);
    return;
  }
  serveChild.on('error', (error) => {
    serveSpawnError = String(error);
    console.error('OPENCODE_DESKTOP spawn error: ' + serveSpawnError);
  });
  serveChild.on('exit', () => { serveChild = null; });
}

function stopServer() {
  if (!serveChild) return;
  try { serveChild.kill(); } catch (error) { console.error('OPENCODE_DESKTOP kill failed: ' + String(error)); }
  serveChild = null;
}

function installAuthHook(win) {
  win.webContents.session.webRequest.onBeforeSendHeaders({ urls: [origin + '/*'] }, (details, callback) => {
    details.requestHeaders.Authorization = authHeader;
    callback({ requestHeaders: details.requestHeaders });
  });
}

async function drive(win) {
  if (!configured) {
    await win.loadFile(path.join(__dirname, 'waiting.html'), { hash: 'not-configured' });
    return;
  }
  installAuthHook(win);
  let waiting = false;
  let lastSpawnAttempt = 0;
  for (;;) {
    if (win.isDestroyed()) return;
    if (await serverUp(2000)) {
      await win.loadURL(origin + '/');
      return;
    }
    // Start (or restart) the server ourselves. A freshly exited child is
    // retried at most every 10s so a crash loop cannot spin CPU.
    if (canAutoStart && !serveChild && Date.now() - lastSpawnAttempt > 10000) {
      lastSpawnAttempt = Date.now();
      spawnServer();
    }
    if (!waiting) {
      waiting = true;
      await win.loadFile(path.join(__dirname, 'waiting.html'), { hash: serveSpawnError ? 'spawn-failed' : 'waiting' });
    }
    await new Promise((resolve) => setTimeout(resolve, 3000));
  }
}

app.whenReady().then(() => {
  const win = new BrowserWindow({
    width: 1280,
    height: 800,
    autoHideMenuBar: true,
    webPreferences: { contextIsolation: true, sandbox: true, nodeIntegration: false },
  });
  win.setWindowButtonVisibility(true);
  win.webContents.on('render-process-gone', (_event, details) => {
    console.error('OPENCODE_DESKTOP_RENDER_EXIT ' + JSON.stringify(details));
  });
  drive(win).catch((error) => console.error('OPENCODE_DESKTOP drive failed: ' + String(error)));
}).catch((error) => {
  console.error(error);
  app.exit(1);
});
app.on('before-quit', stopServer);
app.on('window-all-closed', () => {
  stopServer();
  app.quit();
});
