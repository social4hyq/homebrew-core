'use strict';
// ZCode desktop shell for OpenHarmony.
// Loads the host `zcode --web` instance (loopback HTTP) in an Electron window.
// Connection parameters are baked into config.json by `zcode-desktop install`
// before HAP signing; the bottle HAP only carries a placeholder.
const { app, BrowserWindow, shell } = require('electron');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');

let config = { port: 0, workspace: '' };
try {
  Object.assign(config, JSON.parse(fs.readFileSync(path.join(__dirname, 'config.json'), 'utf8')));
} catch (error) {
  console.error('ZCODE_DESKTOP config unreadable: ' + String(error));
}
const configured = Number.isInteger(config.port) && config.port > 0;
const origin = configured ? `http://127.0.0.1:${config.port}` : null;

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
  // Links the workbench opens in a new window: loopback stays in the shell,
  // external URLs go to the system browser (the shell has no second window).
  win.webContents.setWindowOpenHandler(({ url }) => {
    if (origin && url.startsWith(origin + '/')) {
      win.loadURL(url).catch(() => {});
    } else if (/^https?:/i.test(url)) {
      shell.openExternal(url).catch(() => {});
    }
    return { action: 'deny' };
  });
  win.webContents.on('render-process-gone', (_event, details) => {
    console.error('ZCODE_DESKTOP_RENDER_EXIT ' + JSON.stringify(details));
  });
  drive(win).catch((error) => console.error('ZCODE_DESKTOP drive failed: ' + String(error)));
}).catch((error) => {
  console.error(error);
  app.exit(1);
});
app.on('window-all-closed', () => app.quit());
