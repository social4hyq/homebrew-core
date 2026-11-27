'use strict';

// Runs the shell's real main.cjs against a stand-in for electron and prints what it
// did: the pages the window loaded and what the shell started. argv[2] is the
// directory holding a copy of the app files (its config.json decides the backend).
const Module = require('node:module');
const path = require('node:path');

const appDir = process.argv[2];
const loaded = [];
const handlers = {};
const fs = require('node:fs');
const registration = () => {
  try { return JSON.parse(fs.readFileSync(path.join(process.env.HOME, '.config/magpie-app/web.json'), 'utf8')); } catch { return null; }
};
// What quitting the app does, so a backend the shell started goes with it.
const quit = () => {
  if (handlers['before-quit']) handlers['before-quit']();
  process.stdout.write('@@AFTER@@' + JSON.stringify({ registration: registration() }) + '\n');
  process.exit(0);
};
const done = () => {
  process.stdout.write('@@RESULT@@' + JSON.stringify({ loaded, registration: registration() }) + '\n');
  // SHELL_HOLD keeps the app "open" until stdin closes, so a test can look at it.
  if (process.env.SHELL_HOLD) process.stdin.on('end', quit).resume();
  else quit();
};

class Window {
  constructor() {
    this.webContents = {
      session: { setPermissionRequestHandler() {}, setPermissionCheckHandler() {} },
      on() {}, setWindowOpenHandler() {},
    };
  }
  on() {}
  isDestroyed() { return false; }
  loadURL(url) {
    loaded.push(url);
    // The first page that is not the shell's own is the answer; the shell's own
    // pages (connect.html#...) are the waiting and failure screens.
    if (!url.startsWith('file:')) setTimeout(done, 50);
    else if (/#(failed|manual)$/.test(url)) setTimeout(done, 50);
    return Promise.resolve();
  }
}
class Tray {
  setToolTip() {} on() {} setContextMenu() {} destroy() {}
}
const electron = {
  app: {
    requestSingleInstanceLock: () => true,
    on: (event, handler) => { handlers[event] = handler; },
    whenReady: () => Promise.resolve(),
    getPath: () => process.env.TMPDIR || '/tmp',
    quit() {}, exit() {},
  },
  BrowserWindow: Window,
  Menu: { setApplicationMenu() {}, buildFromTemplate: () => ({}) },
  Tray,
  nativeImage: { createFromPath: () => ({}) },
  shell: { openExternal: () => Promise.resolve() },
};
const load = Module._load;
Module._load = function (request, ...rest) {
  return request === 'electron' ? electron : load.call(this, request, ...rest);
};
require(path.join(appDir, 'main.cjs'));
setTimeout(() => { process.stdout.write('@@RESULT@@' + JSON.stringify({ loaded, timedOut: true }) + '\n'); process.exit(0); }, 20000);
