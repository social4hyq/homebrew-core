'use strict';
// OpenCode desktop shell for OpenHarmony.
// Connects to the background service `opencode service` runs for the terminal
// (the TUI, `opencode run` and this shell share one process, so they see the
// same sessions) and injects HTTP basic auth for its origin. The service's
// address and password come from its state file, not from this package. The
// host `opencode` binary and the host environment it needs are baked into
// config.json by `opencode-app install` before HAP signing. On launch the shell
// starts the service when it is not running (requires the CUSTOM_SANDBOX /
// READ_WRITE_USER_FILE ACLs) and never stops it itself. A service started by
// this shell still ends when the app process ends (`aa force-stop`, tray quit):
// measured on the device, detaching does not keep it alive. Only a service
// started from a terminal outlives the app.
const { app, BrowserWindow } = require('electron');
const { spawn } = require('node:child_process');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const tray = require('./tray.cjs');

let config = {};
try {
  Object.assign(config, JSON.parse(fs.readFileSync(path.join(__dirname, 'config.json'), 'utf8')));
} catch (error) {
  console.error('OPENCODE_DESKTOP config unreadable: ' + String(error));
}
const host = config.host && typeof config.host === 'object' ? config.host : {};
const configured = typeof host.home === 'string' && host.home.length > 0;
const canAutoStart = configured && typeof config.opencode === 'string' && config.opencode.length > 0;

let serveSpawnError = '';
// DSH-style switch: OPENCODE_DESKTOP_NO_TRAY=1 (or "tray": false in config.json)
// restores the old behaviour where closing the window quits the shell.
const useTray = process.env.OPENCODE_DESKTOP_NO_TRAY !== '1' && config.tray !== false;
let trayReady = false;
let shellWindow = null;
let driving = false;

// The state file `opencode service` writes: {"url", "password", "pid", ...}.
// An empty xdgState means the host did not define XDG_STATE_HOME.
function serviceStatePath() {
  const state = typeof host.xdgState === 'string' && host.xdgState ? host.xdgState : path.join(host.home, '.local', 'state');
  return path.join(state, 'opencode', 'service.json');
}

// Returns {origin, port, authHeader} or null. The password is only ever sent
// to a loopback address.
function readService() {
  if (!configured) return null;
  try {
    const state = JSON.parse(fs.readFileSync(serviceStatePath(), 'utf8'));
    const url = new URL(state.url);
    if (url.protocol !== 'http:' || (url.hostname !== '127.0.0.1' && url.hostname !== 'localhost')) return null;
    if (typeof state.password !== 'string' || !state.password) return null;
    return {
      origin: url.origin,
      hostname: url.hostname,
      port: Number(url.port),
      authHeader: 'Basic ' + Buffer.from(`opencode:${state.password}`, 'utf8').toString('base64'),
    };
  } catch (error) {
    return null;
  }
}

function serviceUp(service, timeoutMs) {
  return new Promise((resolve) => {
    const req = http.get({
      host: service.hostname, port: service.port, path: '/api/config',
      headers: { Authorization: service.authHeader }, timeout: timeoutMs, agent: false,
    }, (res) => {
      res.resume();
      resolve(res.statusCode === 200);
    });
    req.on('timeout', () => { req.destroy(); resolve(false); });
    req.on('error', () => resolve(false));
  });
}

function serveLogPath() {
  try {
    const dir = path.join(host.home, '.cache', 'opencode-desktop');
    fs.mkdirSync(dir, { recursive: true });
    return path.join(dir, 'serve.log');
  } catch (error) {
    console.error('OPENCODE_DESKTOP host log dir unavailable: ' + String(error));
  }
  return path.join(app.getPath('userData'), 'opencode-serve.log');
}

// `opencode service start` is idempotent and returns once the background
// service is up; the service itself is not a child of this shell.
function startService() {
  if (!canAutoStart) return;
  const env = Object.assign({}, process.env);
  // The command runs in the app sandbox with the weak-sandbox ACLs: host paths
  // are reachable, but HOME/XDG must point at the real host values so the
  // service shares the TUI's database, configuration and state file.
  env.HOME = host.home;
  if (typeof host.path === 'string') env.PATH = host.path;
  // An empty value means "the host did not define it"; drop the sandbox's
  // inherited value instead of pointing the service at a sandbox path.
  for (const [key, envKey] of [['xdgConfig', 'XDG_CONFIG_HOME'], ['xdgData', 'XDG_DATA_HOME'], ['xdgState', 'XDG_STATE_HOME']]) {
    if (typeof host[key] !== 'string') continue;
    if (host[key]) env[envKey] = host[key];
    else delete env[envKey];
  }
  // Temp files must stay inside the sandbox; the host TMPDIR may be denied.
  env.TMPDIR = app.getPath('temp');

  let logFd;
  try {
    logFd = fs.openSync(serveLogPath(), 'a');
    fs.writeSync(logFd, `\n[shell] ${new Date().toISOString()} ${config.opencode} service start ` +
      `HOME=${env.HOME} TMPDIR=${env.TMPDIR} XDG_CONFIG_HOME=${env.XDG_CONFIG_HOME === undefined ? '<unset>' : env.XDG_CONFIG_HOME}\n`);
  } catch (error) {
    console.error('OPENCODE_DESKTOP cannot open serve log: ' + String(error));
    logFd = undefined;
  }
  const stdio = ['ignore', logFd === undefined ? 'ignore' : logFd, logFd === undefined ? 'ignore' : logFd];
  try {
    // detached + unref so the shell does not wait for it. This does not keep
    // the service alive after the app process ends (see the header).
    const child = spawn(config.opencode, ['service', 'start'], { env, cwd: host.home, stdio, detached: true });
    child.on('error', (error) => {
      serveSpawnError = String(error);
      console.error('OPENCODE_DESKTOP spawn error: ' + serveSpawnError);
    });
    child.unref();
    serveSpawnError = '';
  } catch (error) {
    serveSpawnError = String(error);
    console.error('OPENCODE_DESKTOP spawn failed: ' + serveSpawnError);
  }
}

// The service address can change between runs, so the auth hook follows it.
let hookedOrigin = null;
function installAuthHook(win, service) {
  if (hookedOrigin === service.origin) return;
  hookedOrigin = service.origin;
  win.webContents.session.webRequest.onBeforeSendHeaders({ urls: [service.origin + '/*'] }, (details, callback) => {
    details.requestHeaders.Authorization = service.authHeader;
    callback({ requestHeaders: details.requestHeaders });
  });
}

async function drive(win) {
  if (!configured) {
    await win.loadFile(path.join(__dirname, 'waiting.html'), { hash: 'not-configured' });
    return;
  }
  let waiting = false;
  let lastStartAttempt = 0;
  for (;;) {
    if (win.isDestroyed()) return;
    const service = readService();
    if (service && await serviceUp(service, 2000)) {
      installAuthHook(win, service);
      await win.loadURL(service.origin + '/');
      return;
    }
    // Start the service ourselves, at most every 10s so a failing start cannot
    // spin CPU.
    if (canAutoStart && Date.now() - lastStartAttempt > 10000) {
      lastStartAttempt = Date.now();
      startService();
    }
    if (!waiting) {
      waiting = true;
      await win.loadFile(path.join(__dirname, 'waiting.html'), { hash: serveSpawnError ? 'spawn-failed' : 'waiting' });
    }
    await new Promise((resolve) => setTimeout(resolve, canAutoStart && !serveSpawnError ? 500 : 3000));
  }
}

// Only one drive loop at a time: the tray's restart action re-enters it.
function startDrive() {
  if (driving || !shellWindow || shellWindow.isDestroyed()) return;
  driving = true;
  drive(shellWindow)
    .catch((error) => console.error('OPENCODE_DESKTOP drive failed: ' + String(error)))
    .finally(() => { driving = false; });
}

app.whenReady().then(() => {
  // The status bar item has to exist before the first window: electron-ohos
  // attaches every BrowserWindow UIAbility to it, and hideAbility() only keeps
  // the process alive while the item exists.
  if (useTray) {
    try {
      tray.create({
        tooltip: 'OpenCode',
        iconPath: path.join(__dirname, 'tray-icon.png'),
        restartLabel: '重新连接后端',
        onRestartBackend: startDrive,
      });
      trayReady = true;
    } catch (error) {
      console.error('OPENCODE_DESKTOP tray unavailable: ' + String(error));
    }
  }

  shellWindow = new BrowserWindow({
    backgroundColor: "#11141b",
    width: 1280,
    height: 800,
    autoHideMenuBar: true,
    webPreferences: { contextIsolation: true, sandbox: true, nodeIntegration: false },
  });
  shellWindow.setWindowButtonVisibility(true);
  shellWindow.webContents.on('render-process-gone', (_event, details) => {
    console.error('OPENCODE_DESKTOP_RENDER_EXIT ' + JSON.stringify(details));
  });
  if (trayReady) tray.attach(shellWindow);
  startDrive();
}).catch((error) => {
  console.error(error);
  app.exit(1);
});

app.on('before-quit', (event) => {
  // A system-level close request (dock "close", session end) reaches Electron
  // as before-quit; veto it and hide to the tray instead of exiting.
  if (trayReady && !tray.isQuitting()) {
    event.preventDefault();
    if (shellWindow && !shellWindow.isDestroyed()) shellWindow.hide();
    return;
  }
});

app.on('window-all-closed', () => {
  // With a tray the window is only hidden, never closed; keep the process
  // alive. Without a tray, keep the old behaviour. The shell never stops the
  // service explicitly: `opencode-app stop` (or `opencode service stop`) does.
  if (trayReady) return;
  app.quit();
});
