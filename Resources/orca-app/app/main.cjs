'use strict';
// Orca desktop shell for OpenHarmony.
// Starts the host `orca` runtime server itself when it is not already running
// and loads its browser client (loopback HTTP) in an Electron window, the way
// the other desktop shells in this tap do.
//
// The runtime mints a single-use pairing link on every start, so no URL is
// baked into the HAP: `orca serve --json` prints a ready record with the
// current link, which this shell tails from the server log. `orca-app install`
// only writes the port, the runtime binary path and the host environment.
// Spawning host binaries and reading the host home directory need the
// CUSTOM_SANDBOX / READ_WRITE_USER_FILE ACLs.
const { app, BrowserWindow, shell } = require('electron');
const { spawn } = require('node:child_process');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const tray = require('./tray.cjs');

let config = { port: 0 };
try {
  Object.assign(config, JSON.parse(fs.readFileSync(path.join(__dirname, 'config.json'), 'utf8')));
} catch (error) {
  console.error('ORCA_DESKTOP config unreadable: ' + String(error));
}
const configured = Number.isInteger(config.port) && config.port > 0;
const origin = configured ? `http://127.0.0.1:${config.port}` : null;
const host = config.host && typeof config.host === 'object' ? config.host : {};
const canAutoStart = configured && typeof config.orca === 'string' && config.orca.length > 0;

let serveChild = null;
let serveFailure = '';
// ORCA_DESKTOP_NO_TRAY=1 (or "tray": false in config.json) restores the old
// behaviour where closing the window quits the shell.
const useTray = process.env.ORCA_DESKTOP_NO_TRAY !== '1' && config.tray !== false;
let trayReady = false;
let shellWindow = null;
let driving = false;

function serverUp(timeoutMs) {
  return new Promise((resolve) => {
    if (!configured) return resolve(false);
    const req = http.get({
      host: '127.0.0.1', port: config.port, path: '/web-index.html',
      timeout: timeoutMs, agent: false,
    }, (res) => {
      res.resume();
      resolve(res.statusCode === 200);
    });
    req.on('timeout', () => { req.destroy(); resolve(false); });
    req.on('error', () => resolve(false));
  });
}

function serveLogPath() {
  if (typeof host.home === 'string' && host.home.length > 0) {
    try {
      const dir = path.join(host.home, '.cache', 'orca-desktop');
      fs.mkdirSync(dir, { recursive: true });
      return path.join(dir, 'serve.log');
    } catch (error) {
      console.error('ORCA_DESKTOP host log dir unavailable: ' + String(error));
    }
  }
  return path.join(app.getPath('userData'), 'orca-serve.log');
}

// Everything the runtime needs from the host is baked into config.json at
// install time. The shell itself runs in the app sandbox, so HOME/PATH/XDG have
// to be restored for the child to see the same profile as the host CLI.
function childEnv() {
  const env = Object.assign({}, process.env);
  if (typeof host.home === 'string' && host.home.length > 0) env.HOME = host.home;
  if (typeof host.path === 'string' && host.path.length > 0) env.PATH = host.path;
  // An empty value means "the host did not define it"; drop the sandbox's
  // inherited value instead of pointing the runtime at a sandbox path.
  for (const [key, envKey] of [['xdgConfig', 'XDG_CONFIG_HOME'], ['xdgData', 'XDG_DATA_HOME'],
    ['xdgState', 'XDG_STATE_HOME']]) {
    if (typeof host[key] !== 'string') continue;
    if (host[key]) env[envKey] = host[key];
    else delete env[envKey];
  }
  // The runtime's data root holds its SQLite state, instance lock and private
  // files; keep it in this app's sandbox so a force-stop cannot leave a lock
  // that the shared home mount makes impossible to check (HMDFS reports a
  // distributed filesystem, so a dead holder is "unverifiable" there).
  env.ORCA_USER_DATA = typeof host.dataRoot === 'string' && host.dataRoot.length > 0
    ? host.dataRoot
    : path.join(app.getPath('userData'), 'orca-data');
  // The runtime's Unix sockets and terminal ledger live under TMPDIR on
  // HarmonyOS (the home mount rejects sockets); the host TMPDIR belongs to
  // another app's sandbox, so keep them in this shell's own temp directory.
  env.TMPDIR = app.getPath('temp');
  env.XDG_RUNTIME_DIR = app.getPath('temp');
  return env;
}

function spawnServer() {
  if (!canAutoStart || serveChild) return;
  const env = childEnv();
  const logPath = serveLogPath();
  let logFd;
  try {
    logFd = fs.openSync(logPath, 'a');
    fs.writeSync(logFd, `\n[shell] ${new Date().toISOString()} spawn ${config.orca} serve --port ` +
      `${config.port} HOME=${env.HOME} ORCA_USER_DATA=${env.ORCA_USER_DATA || '<default>'} ` +
      `TMPDIR=${env.TMPDIR}\n`);
  } catch (error) {
    console.error('ORCA_DESKTOP cannot open serve log: ' + String(error));
  }
  try {
    serveChild = spawn(config.orca, ['serve', '--port', String(config.port), '--json'], {
      env,
      cwd: typeof host.home === 'string' && host.home.length > 0 ? host.home : undefined,
      stdio: ['ignore', logFd === undefined ? 'ignore' : logFd, logFd === undefined ? 'ignore' : logFd],
    });
  } catch (error) {
    serveFailure = String(error);
    console.error('ORCA_DESKTOP spawn failed: ' + serveFailure);
    return;
  }
  if (logFd !== undefined) {
    try { fs.closeSync(logFd); } catch {}
  }
  serveChild.on('error', (error) => {
    serveFailure = String(error);
    console.error('ORCA_DESKTOP spawn error: ' + serveFailure);
  });
  serveChild.on('exit', (code, signal) => {
    serveChild = null;
    serveFailure = `server exited (code ${code}, signal ${signal})`;
    console.error('ORCA_DESKTOP_ORCAD_EXIT ' + serveFailure);
  });
}

function stopServer() {
  if (!serveChild) return;
  try { serveChild.kill(); } catch (error) { console.error('ORCA_DESKTOP kill failed: ' + String(error)); }
  serveChild = null;
}

// The ready record is the only place the single-use pairing link appears.
function currentPairingUrl() {
  let text;
  try {
    text = fs.readFileSync(serveLogPath(), 'utf8');
  } catch {
    return null;
  }
  const lines = text.split('\n');
  // Only records written after our own last spawn belong to the server on this
  // port; an older instance's link is single use and already redeemed.
  let start = 0;
  for (let index = 0; index < lines.length; index += 1) {
    if (lines[index].startsWith('[shell]')) start = index;
  }
  let url = null;
  for (let index = start; index < lines.length; index += 1) {
    const line = lines[index];
    if (!line.includes('orca_server_ready')) continue;
    try {
      const ready = JSON.parse(line);
      const candidate = ready && ready.pairing && ready.pairing.webClientUrl;
      if (typeof candidate === 'string' && candidate.startsWith(origin + '/')) url = candidate;
    } catch {}
  }
  return url;
}

// The HTTP port answers a moment before the ready record reaches the log; wait
// for it so the shell never opens the client without its pairing link.
async function waitForPairingUrl(timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  for (;;) {
    const url = currentPairingUrl();
    if (url) return url;
    if (Date.now() >= deadline) return null;
    await new Promise((resolve) => setTimeout(resolve, 200));
  }
}

function showWaiting(win, state) {
  return win.loadFile(path.join(__dirname, 'waiting.html'), {
    query: { state, origin: origin || '' },
  });
}

async function drive(win) {
  if (!configured) {
    await showWaiting(win, 'not-configured');
    return;
  }
  let waiting = false;
  let lastSpawn = 0;
  let spawnDelay = 5000;
  const fastPollUntil = Date.now() + 120000;
  for (;;) {
    if (win.isDestroyed()) return;
    if (await serverUp(2000)) {
      const url = (await waitForPairingUrl(6000)) || origin + '/web-index.html';
      await win.loadURL(url);
      return;
    }
    const now = Date.now();
    if (canAutoStart && !serveChild && now - lastSpawn > spawnDelay) {
      lastSpawn = now;
      // Back off while the runtime keeps dying; reset once it stays up.
      if (serveFailure) spawnDelay = Math.min(spawnDelay * 2, 60000);
      spawnServer();
    }
    if (!waiting) {
      waiting = true;
      await showWaiting(win, 'waiting');
    }
    // Detect startup promptly, then back off if the runtime stays down.
    await new Promise((resolve) => setTimeout(resolve, Date.now() < fastPollUntil ? 250 : 3000));
  }
}

// Only one drive loop at a time.
function startDrive() {
  if (driving || !shellWindow || shellWindow.isDestroyed()) return;
  driving = true;
  drive(shellWindow)
    .catch((error) => console.error('ORCA_DESKTOP drive failed: ' + String(error)))
    .finally(() => { driving = false; });
}

app.whenReady().then(() => {
  // The status bar item has to exist before the first window: electron-ohos
  // attaches every BrowserWindow UIAbility to it, and hideAbility() only keeps
  // the process alive while the item exists.
  if (useTray) {
    try {
      tray.create({
        tooltip: 'Orca',
        iconPath: path.join(__dirname, 'tray-icon.png'),
        onQuit: stopServer,
      });
      trayReady = true;
    } catch (error) {
      console.error('ORCA_DESKTOP tray unavailable: ' + String(error));
    }
  }

  shellWindow = new BrowserWindow({
    backgroundColor: '#0f1115',
    width: 1280,
    height: 800,
    autoHideMenuBar: true,
    webPreferences: { contextIsolation: true, sandbox: true, nodeIntegration: false },
  });
  // Links the workbench opens in a new window: loopback stays in the shell,
  // external URLs go to the system browser (the shell has no second window).
  shellWindow.webContents.setWindowOpenHandler(({ url }) => {
    if (origin && url.startsWith(origin + '/')) {
      shellWindow.loadURL(url).catch(() => {});
    } else if (/^https?:/i.test(url)) {
      shell.openExternal(url).catch(() => {});
    }
    return { action: 'deny' };
  });
  shellWindow.webContents.on('render-process-gone', (_event, details) => {
    console.error('ORCA_DESKTOP_RENDER_EXIT ' + JSON.stringify(details));
  });
  if (trayReady) tray.attach(shellWindow);
  startDrive();
}).catch((error) => {
  console.error(error);
  app.exit(1);
});

app.on('before-quit', (event) => {
  // A system-level close request (dock "close", session end) reaches Electron
  // as before-quit; veto it and hide to the tray instead of exiting. The
  // spawned runtime keeps serving so the window reopens instantly.
  if (trayReady && !tray.isQuitting()) {
    event.preventDefault();
    if (shellWindow && !shellWindow.isDestroyed()) shellWindow.hide();
  }
});

app.on('window-all-closed', () => {
  // With a tray the window is only hidden, never closed.
  if (trayReady) return;
  stopServer();
  app.quit();
});

app.on('will-quit', stopServer);
