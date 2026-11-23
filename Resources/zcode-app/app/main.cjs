'use strict';
// ZCode desktop shell for OpenHarmony.
// Loads the host `zcode --web` instance (loopback HTTP) in an Electron window.
// Connection parameters are baked into config.json by `zcode-app install`
// before HAP signing; the bottle HAP only carries a placeholder. When the
// service is not up on launch the shell starts it by running the host
// `zcode-app serve` (idempotent; requires the CUSTOM_SANDBOX /
// READ_WRITE_USER_FILE ACLs). The shell never stops the service itself, but a
// service it started ends with the app (aa force-stop, tray quit): detaching
// does not leave the app's cgroup, measured on the device. Only a service
// started from a terminal outlives the app, so the tray quit asks first when
// the shell started the service (lifecycle.cjs).
const { app, BrowserWindow, dialog, shell } = require('electron');
const { spawn } = require('node:child_process');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const lifecycle = require('./lifecycle.cjs');
const serverAuth = require('./server-auth.cjs');
const tray = require('./tray.cjs');

let config = { port: 0, workspace: '' };
try {
  Object.assign(config, JSON.parse(fs.readFileSync(path.join(__dirname, 'config.json'), 'utf8')));
} catch (error) {
  console.error('ZCODE_DESKTOP config unreadable: ' + String(error));
}
const configured = Number.isInteger(config.port) && config.port > 0;
const origin = configured ? `http://127.0.0.1:${config.port}` : null;
// config.launcher is the host `zcode-app` wrapper and config.host the install-time
// HOME/PATH/XDG values it needs. Without a launcher (strong-sandbox install, or a
// config written by an older `zcode-app install`) the shell only waits.
const canAutoStart = configured && typeof config.launcher === 'string' && config.launcher.length > 0;
// The service rejects /api and /ws without its token. The wrapper creates the
// token file when it starts the service, so it is read on every probe rather
// than once at startup.
const tokenPath = serverAuth.tokenFile(config.host, process.env);
function currentToken() {
  return serverAuth.readToken(fs, tokenPath);
}
let serveChild = null;
let serveSpawnError = '';
// True once this shell had to start the service (it was not up when the shell
// connected). Such a service ends with the app; one that was already running is
// not affected by quitting.
let startedService = false;

// ZCODE_DESKTOP_NO_TRAY=1 (or "tray": false in config.json) restores the old
// behaviour where closing the window quits the shell.
const useTray = process.env.ZCODE_DESKTOP_NO_TRAY !== '1' && config.tray !== false;
let trayReady = false;
let shellWindow = null;
let driving = false;

// zcode://oauth/callback comes back from the browser after a successful login.
// The web client finishes the login through the server poll; the handoff only
// has to reach the app, so bring the shell forward when it is delivered.
function focusShellWindow() {
  if (trayReady) {
    tray.showWindow();
    return;
  }
  const target = BrowserWindow.getAllWindows()[0];
  if (!target || target.isDestroyed()) return;
  if (target.isMinimized()) target.restore();
  target.show();
  target.focus();
}
app.on('open-url', (event, url) => {
  event.preventDefault();
  if (/^zcode:\/\//i.test(url)) focusShellWindow();
});
for (const arg of process.argv.slice(1)) {
  if (/^zcode:\/\//i.test(arg)) app.whenReady().then(focusShellWindow);
}

function serverUp(timeoutMs) {
  return new Promise((resolve) => {
    if (!configured) return resolve(false);
    // Without a token there is nothing to authenticate with yet: the service is
    // not usable until the wrapper has created it and started a protected one.
    const token = currentToken();
    if (!token) return resolve(false);
    const req = http.get({
      host: '127.0.0.1', port: config.port, path: '/api/server-info',
      headers: serverAuth.infoHeaders(token),
      timeout: timeoutMs, agent: false,
    }, (res) => {
      let body = '';
      res.setEncoding('utf8');
      res.on('data', (chunk) => { if (body.length < 65536) body += chunk; });
      res.on('end', () => resolve(serverAuth.acceptServerInfo(res.statusCode, body)));
      res.on('error', () => resolve(false));
    });
    req.on('timeout', () => { req.destroy(); resolve(false); });
    req.on('error', () => resolve(false));
  });
}

function serveLogPath() {
  return path.join(app.getPath('userData'), 'zcode-serve.log');
}

// Run `zcode-app serve`: it prepares the patched server, creates the credential
// secret, starts the service in the background and returns once it is healthy
// (or after ~40s with an error). It exits at once when the service is already up.
function spawnService() {
  if (!canAutoStart || serveChild) return;
  const host = config.host && typeof config.host === 'object' ? config.host : {};
  const env = Object.assign({}, process.env);
  // The child runs in the app sandbox with the weak-sandbox ACLs: host paths
  // are reachable, but HOME/PATH/XDG must be the real host values so the
  // launcher finds the same config, credential secret and tools as the CLI.
  if (typeof host.home === 'string' && host.home.length > 0) env.HOME = host.home;
  if (typeof host.path === 'string' && host.path.length > 0) env.PATH = host.path;
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
    fs.writeSync(logFd, `\n[shell] ${new Date().toISOString()} spawn ${config.launcher} serve HOME=${env.HOME}\n`);
  } catch (error) {
    console.error('ZCODE_DESKTOP cannot open serve log: ' + String(error));
    logFd = undefined;
  }
  try {
    serveChild = spawn(config.launcher, ['serve'], {
      env,
      cwd: typeof host.home === 'string' && host.home.length > 0 ? host.home : undefined,
      // Detached, so the background service the launcher starts does not share
      // the shell's process group. It still belongs to the app's cgroup and
      // ends when the app does.
      detached: true,
      stdio: ['ignore', logFd === undefined ? 'ignore' : logFd, logFd === undefined ? 'ignore' : logFd],
    });
  } catch (error) {
    serveSpawnError = String(error);
    console.error('ZCODE_DESKTOP spawn failed: ' + serveSpawnError);
    return;
  }
  serveChild.on('error', (error) => {
    serveSpawnError = String(error);
    console.error('ZCODE_DESKTOP spawn error: ' + serveSpawnError);
    serveChild = null;
  });
  serveChild.on('exit', (code, signal) => {
    serveChild = null;
    serveSpawnError = code === 0 ? '' : `zcode-app serve exited with ${code === null ? signal : code}`;
    if (serveSpawnError) console.error('ZCODE_DESKTOP ' + serveSpawnError);
  });
  serveChild.unref();
}

function showWaiting(win, state) {
  return win.loadFile(path.join(__dirname, 'waiting.html'), {
    query: {
      state,
      origin: origin || '',
      workspace: String(config.workspace || ''),
    },
  });
}

async function drive(win) {
  if (!configured) {
    await showWaiting(win, 'not-configured');
    return;
  }
  let shown = '';
  let lastSpawnAttempt = 0;
  const fastPollUntil = Date.now() + 30000;
  for (;;) {
    if (win.isDestroyed()) return;
    if (await serverUp(2000)) {
      try {
        fs.appendFileSync(serveLogPath(), `[attach] ${new Date().toISOString()} ${lifecycle.attachLine({ startedService })}\n`);
      } catch {}
      await win.loadURL(serverAuth.authedUrl(origin, currentToken()));
      return;
    }
    // Start the service ourselves. A finished attempt is retried at most every
    // 10s so a failing launcher cannot spin the CPU.
    if (canAutoStart && !serveChild && Date.now() - lastSpawnAttempt > 10000) {
      lastSpawnAttempt = Date.now();
      startedService = true;
      spawnService();
    }
    const state = serveSpawnError ? 'spawn-failed' : 'waiting';
    if (state !== shown) {
      shown = state;
      await showWaiting(win, state);
    }
    // Detect startup promptly, then back off if the host service stays down.
    await new Promise((resolve) => setTimeout(resolve, serveChild || Date.now() < fastPollUntil ? 250 : 3000));
  }
}

// Tray "退出应用". Quitting ends a service this shell started, so ask first. A
// second click while the question is open quits anyway, and anything that goes
// wrong while asking (dialog failure) quits as before.
let confirming = false;
async function confirmQuit() {
  if (confirming) {
    app.exit(0);
    return;
  }
  confirming = true;
  try {
    if (lifecycle.shouldConfirmQuit({ startedService, serviceUp: await serverUp(2000) })) {
      let proceed = true;
      try {
        tray.showWindow();
        const parent = shellWindow && !shellWindow.isDestroyed() ? shellWindow : undefined;
        const { response } = await dialog.showMessageBox(parent, lifecycle.quitDialog());
        proceed = lifecycle.confirmedQuit(response);
      } catch (error) {
        console.error('ZCODE_DESKTOP quit dialog failed: ' + String(error));
      }
      if (!proceed) return;
    }
    // The shell's ArkTS windowStageClose handler refuses to close the window, so
    // a regular app.quit() would be vetoed; exit the process directly.
    app.exit(0);
  } finally {
    confirming = false;
  }
}

// Only one drive loop at a time.
function startDrive() {
  if (driving || !shellWindow || shellWindow.isDestroyed()) return;
  driving = true;
  drive(shellWindow)
    .catch((error) => console.error('ZCODE_DESKTOP drive failed: ' + String(error)))
    .finally(() => { driving = false; });
}

app.whenReady().then(() => {
  // The status bar item has to exist before the first window: electron-ohos
  // attaches every BrowserWindow UIAbility to it, and hideAbility() only keeps
  // the process alive while the item exists.
  if (useTray) {
    try {
      // The menu is set once, inside create(), with a quit that can ask first:
      // a second setContextMenu() right after create() was sometimes refused.
      tray.create({
        tooltip: 'ZCode',
        iconPath: path.join(__dirname, 'tray-icon.png'),
        onQuitRequest: confirmQuit,
      });
      trayReady = true;
    } catch (error) {
      console.error('ZCODE_DESKTOP tray unavailable: ' + String(error));
    }
  }

  shellWindow = new BrowserWindow({
    backgroundColor: "#11141b",
    width: 1280,
    height: 800,
    autoHideMenuBar: true,
    webPreferences: { contextIsolation: true, sandbox: true, nodeIntegration: false },
  });
  // The OHOS shell provides the system window buttons itself.
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
    console.error('ZCODE_DESKTOP_RENDER_EXIT ' + JSON.stringify(details));
  });
  if (trayReady) tray.attach(shellWindow);
  startDrive();
}).catch((error) => {
  console.error(error);
  app.exit(1);
});

app.on('before-quit', (event) => {
  // A system-level close request (dock "close", session end) reaches Electron
  // as before-quit; veto it and hide to the tray instead of exiting. Hiding
  // does not touch the service; only an actual exit (tray quit, force-stop)
  // ends a service this shell started.
  if (trayReady && !tray.isQuitting()) {
    event.preventDefault();
    if (shellWindow && !shellWindow.isDestroyed()) shellWindow.hide();
  }
});

app.on('window-all-closed', () => {
  // With a tray the window is only hidden, never closed.
  if (trayReady) return;
  app.quit();
});
