'use strict';
// Orca desktop shell for OpenHarmony.
// Loads the host `orca` runtime server's browser client (loopback HTTP) in an
// Electron window. `orca-app install` bakes the connection URL into config.json
// before the HAP is signed; the bottle HAP only carries a placeholder.
const { app, BrowserWindow, shell } = require('electron');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const tray = require('./tray.cjs');

let config = { port: 0, url: '' };
try {
  Object.assign(config, JSON.parse(fs.readFileSync(path.join(__dirname, 'config.json'), 'utf8')));
} catch (error) {
  console.error('ORCA_DESKTOP config unreadable: ' + String(error));
}
const configured = Number.isInteger(config.port) && config.port > 0;
const origin = configured ? `http://127.0.0.1:${config.port}` : null;
// The pairing code rides in the URL fragment; the web client keeps it after the
// first successful pair, so the baked link only has to work once.
const startUrl = configured
  ? typeof config.url === 'string' && config.url.startsWith(origin + '/')
    ? config.url
    : origin + '/web-index.html'
  : null;

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
  const fastPollUntil = Date.now() + 30000;
  for (;;) {
    if (win.isDestroyed()) return;
    if (await serverUp(2000)) {
      await win.loadURL(startUrl);
      return;
    }
    if (!waiting) {
      waiting = true;
      await showWaiting(win, 'waiting');
    }
    // Detect startup promptly, then back off if the host server stays down.
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
  // as before-quit; veto it and hide to the tray instead of exiting. The host
  // `orca` server this shell talks to is not affected either way.
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
