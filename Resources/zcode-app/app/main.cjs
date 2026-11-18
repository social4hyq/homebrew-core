'use strict';
// ZCode desktop shell for OpenHarmony.
// Loads the host `zcode --web` instance (loopback HTTP) in an Electron window.
// Connection parameters are baked into config.json by `zcode-app install`
// before HAP signing; the bottle HAP only carries a placeholder.
const { app, BrowserWindow, shell } = require('electron');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const tray = require('./tray.cjs');

let config = { port: 0, workspace: '' };
try {
  Object.assign(config, JSON.parse(fs.readFileSync(path.join(__dirname, 'config.json'), 'utf8')));
} catch (error) {
  console.error('ZCODE_DESKTOP config unreadable: ' + String(error));
}
const configured = Number.isInteger(config.port) && config.port > 0;
const origin = configured ? `http://127.0.0.1:${config.port}` : null;

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
    const req = http.get({
      host: '127.0.0.1', port: config.port, path: '/api/server-info',
      timeout: timeoutMs, agent: false,
    }, (res) => {
      res.resume();
      resolve(res.statusCode === 200);
    });
    req.on('timeout', () => { req.destroy(); resolve(false); });
    req.on('error', () => resolve(false));
  });
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
  let waiting = false;
  const fastPollUntil = Date.now() + 30000;
  for (;;) {
    if (win.isDestroyed()) return;
    if (await serverUp(2000)) {
      await win.loadURL(origin + '/');
      return;
    }
    if (!waiting) {
      waiting = true;
      await showWaiting(win, 'waiting');
    }
    // Detect startup promptly, then back off if the host service stays down.
    await new Promise((resolve) => setTimeout(resolve, Date.now() < fastPollUntil ? 250 : 3000));
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
      tray.create({
        tooltip: 'ZCode',
        iconPath: path.join(__dirname, 'tray-icon.png'),
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
  // as before-quit; veto it and hide to the tray instead of exiting. The host
  // `zcode --web` service this shell talks to is not affected either way.
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
