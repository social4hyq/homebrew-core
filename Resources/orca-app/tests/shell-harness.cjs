'use strict';

// Runs the shell's real main.cjs against a stand-in for electron and reports what it did
// as `@@EVENT@@ {json}` lines: pages loaded, scripts run in the page, dialogs shown,
// app.exit. argv[2] is a directory holding a copy of the app files. stdin takes the
// commands "quit" (click the tray's 退出应用) and "end" (stop).
const Module = require('node:module');
const path = require('node:path');
const readline = require('node:readline');

const appDir = process.argv[2];
const emit = (event) => process.stdout.write('@@EVENT@@' + JSON.stringify(event) + '\n');
const handlers = {};
let menuItems = [];

class Window {
  constructor() {
    this.webContents = {
      session: {}, on() {}, setWindowOpenHandler() {},
      executeJavaScript: async (code) => { emit({ type: 'js', code }); return true; },
    };
  }
  on() {}
  isDestroyed() { return false; }
  isMinimized() { return false; }
  restore() {}
  show() {}
  hide() {}
  focus() {}
  loadFile(file, options) { emit({ type: 'waiting', file: path.basename(file), state: options && options.query && options.query.state }); return Promise.resolve(); }
  loadURL(url) { emit({ type: 'load', url }); return Promise.resolve(); }
}
class Tray {
  setToolTip() {} on() {} destroy() {}
  setContextMenu(menu) { menuItems = menu; }
}
const electron = {
  app: {
    requestSingleInstanceLock: () => true,
    on: (event, handler) => { handlers[event] = handler; },
    whenReady: () => Promise.resolve(),
    getPath: (name) => path.join(process.env.TMPDIR || '/tmp', name === 'temp' ? 'tmp' : 'userData'),
    quit() {},
    exit: (code) => { emit({ type: 'exit', code }); setTimeout(() => process.exit(0), 50); },
  },
  BrowserWindow: Window,
  Menu: { setApplicationMenu() {}, buildFromTemplate: (items) => items },
  Tray,
  nativeImage: { createFromPath: () => ({ isEmpty: () => false }) },
  shell: { openExternal: () => Promise.resolve() },
  dialog: {
    showMessageBox: (parent, options) => {
      emit({ type: 'dialog', options });
      if (process.env.DIALOG_HOLD) return new Promise(() => {});
      return Promise.resolve({ response: Number(process.env.DIALOG_RESPONSE || 0) });
    },
  },
};
const load = Module._load;
Module._load = function (request, ...rest) {
  return request === 'electron' ? electron : load.call(this, request, ...rest);
};
require(path.join(appDir, 'main.cjs'));
// A test that ends the harness by signal still stops the runtime the shell started.
process.on('SIGTERM', () => {
  if (handlers['will-quit']) handlers['will-quit']();
  process.exit(0);
});
readline.createInterface({ input: process.stdin }).on('line', (line) => {
  if (line === 'quit') {
    const item = menuItems.find((entry) => entry.label === '退出应用');
    if (item) item.click();
  } else if (line === 'end') {
    if (handlers['will-quit']) handlers['will-quit']();
    process.exit(0);
  }
});
