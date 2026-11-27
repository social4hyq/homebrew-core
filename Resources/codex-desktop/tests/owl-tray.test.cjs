'use strict';

// The tray module against a stand-in for electron.
const assert = require('node:assert/strict');
const { EventEmitter } = require('node:events');
const test = require('node:test');

const { install } = require('../app/owl-tray.cjs');

class FakeWindow extends EventEmitter {
  constructor(name, visible = true) {
    super();
    this.name = name; this.visible = visible; this.destroyed = false; this.minimized = false; this.focused = false;
  }
  isDestroyed() { return this.destroyed; }
  isVisible() { return this.visible; }
  isMinimized() { return this.minimized; }
  restore() { this.minimized = false; }
  hide() { this.visible = false; }
  show() { this.visible = true; }
  focus() { this.focused = true; }
  // What Electron does for the X button: emit close, and destroy unless it was vetoed.
  requestClose() {
    let prevented = false;
    this.emit('close', { preventDefault: () => { prevented = true; } });
    if (!prevented) this.destroyed = true;
    return prevented;
  }
}

function setup({ owned = null, trayThrows = false, emptyIcon = false, dialogResponse = 1, dialogThrows = false, dialogHeld = false, onQuit = null } = {}) {
  const app = new EventEmitter();
  const calls = { exit: [], menus: [], trays: [], dialogs: [], logs: [], windowsCreated: 0 };
  const ready = [];
  app.whenReady = () => ({ then: (callback) => { ready.push(callback); } });
  app.exit = (code) => calls.exit.push(code);
  const windows = [];
  class Tray extends EventEmitter {
    constructor(icon) {
      super();
      if (trayThrows) throw new Error('no status bar');
      this.icon = icon; this.tooltip = null; calls.trays.push(this);
    }
    setToolTip(text) { this.tooltip = text; }
    setContextMenu(menu) { calls.menus.push(menu); }
  }
  const electron = {
    app,
    BrowserWindow: { getAllWindows: () => windows },
    Menu: { buildFromTemplate: (items) => items },
    Tray,
    nativeImage: { createFromPath: (file) => ({ file, isEmpty: () => emptyIcon }) },
    dialog: {
      showMessageBox: async (parent, options) => {
        calls.dialogs.push({ parent, options });
        if (dialogThrows) throw new Error('no dialog');
        if (dialogHeld) return new Promise(() => {}); // the question stays open
        return { response: dialogResponse };
      },
    },
  };
  const controller = install(electron, { iconPath: '/app/tray-icon.png', ownedServer: () => owned, onQuit, log: (m) => calls.logs.push(m) });
  const open = (name, visible = true) => {
    const win = new FakeWindow(name, visible);
    windows.push(win);
    app.emit('browser-window-created', {}, win);
    return win;
  };
  const start = () => { for (const callback of ready) callback(); };
  return { app, calls, controller, open, start, windows };
}

test('creates the tray when the app is ready, with one menu set once', () => {
  const { calls, start, open } = setup();
  open('before the tray'); // the vendor creates windows after ready, but the listener is already there
  start();
  assert.equal(calls.trays.length, 1);
  assert.equal(calls.trays[0].icon.file, '/app/tray-icon.png');
  assert.equal(calls.trays[0].tooltip, 'ChatGPT');
  assert.equal(calls.menus.length, 1, 'setContextMenu is called once');
  assert.deepEqual(calls.menus[0].filter((item) => item.label).map((item) => item.label), ['显示窗口', '退出应用']);
});

test('closing the last window hides it instead of closing it', () => {
  const { start, open, controller } = setup();
  start();
  const win = open('main');
  assert.equal(win.requestClose(), true, 'the close is vetoed');
  assert.equal(win.destroyed, false);
  assert.equal(win.visible, false);
  assert.equal(controller.isQuitting(), false);
});

test('a window closes normally while another one is open', () => {
  const { start, open } = setup();
  start();
  const main = open('main');
  const popup = open('popup');
  assert.equal(popup.requestClose(), false);
  assert.equal(popup.destroyed, true);
  popup.visible = false;
  assert.equal(main.requestClose(), true, 'now main is the last one');
});

test('a hidden helper window does not keep the last visible one from hiding', () => {
  const { start, open } = setup();
  start();
  open('invisible helper', false);
  const main = open('main');
  assert.equal(main.requestClose(), true);
});

test('showing from the tray brings back the same window and creates none', () => {
  const { calls, start, open, windows } = setup();
  start();
  const win = open('main');
  win.requestClose();
  win.minimized = true;
  const before = windows.length;
  calls.trays[0].emit('click');
  assert.equal(win.visible, true);
  assert.equal(win.minimized, false);
  assert.equal(win.focused, true);
  assert.equal(windows.length, before, 'no new window');
  // And through the menu item.
  win.requestClose();
  calls.menus[0].find((item) => item.label === '显示窗口').click();
  assert.equal(win.visible, true);
});

test('closing again after a restore hides again', () => {
  const { calls, start, open } = setup();
  start();
  const win = open('main');
  win.requestClose();
  calls.trays[0].emit('click');
  assert.equal(win.requestClose(), true);
  assert.equal(win.destroyed, false);
});

test('quit from the tray exits the process and lets the window close', async () => {
  const { calls, start, open, controller } = setup();
  start();
  const win = open('main');
  await calls.menus[0].find((item) => item.label === '退出应用').click();
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(calls.exit, [0]);
  assert.equal(controller.isQuitting(), true);
  assert.equal(calls.dialogs.length, 0, 'nothing to ask when the app owns no server');
  assert.equal(win.requestClose(), false, 'a close during quitting is not vetoed');
});

test('quit asks first when the app started the shared server, and cancel keeps the app', async () => {
  const { calls, start, open } = setup({ owned: { pid: 42 }, dialogResponse: 0 });
  start();
  const win = open('main');
  win.requestClose();
  calls.menus[0].find((item) => item.label === '退出应用').click();
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(calls.dialogs.length, 1);
  assert.match(calls.dialogs[0].options.detail, /共享 Codex 服务/);
  assert.deepEqual(calls.dialogs[0].options.buttons, ['取消', '仍然退出']);
  assert.equal(win.visible, true, 'the window is shown so the question is seen');
  assert.deepEqual(calls.exit, []);
});

test('confirming the question exits', async () => {
  const { calls, start, open } = setup({ owned: { pid: 42 }, dialogResponse: 1 });
  start();
  open('main');
  calls.menus[0].find((item) => item.label === '退出应用').click();
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(calls.exit, [0]);
});

test('a second click while the question is open quits anyway', async () => {
  const { calls, start, open } = setup({ owned: { pid: 42 }, dialogHeld: true });
  start();
  open('main');
  const quit = () => calls.menus[0].find((entry) => entry.label === '退出应用').click();
  quit();
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(calls.exit, [], 'still asking');
  quit();
  assert.deepEqual(calls.exit, [0]);
});

test('a dialog that fails does not trap the user: it quits as before', async () => {
  const { calls, start, open } = setup({ owned: { pid: 42 }, dialogThrows: true });
  start();
  open('main');
  calls.menus[0].find((item) => item.label === '退出应用').click();
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(calls.exit, [0]);
  assert.ok(calls.logs.some((message) => /quit dialog failed/.test(message)));
});

test('without a tray (creation fails) closing is not intercepted', () => {
  const { calls, start, open, controller } = setup({ trayThrows: true });
  start();
  assert.equal(controller.hasTray(), false);
  assert.ok(calls.logs.some((message) => /tray unavailable/.test(message)));
  const win = open('main');
  assert.equal(win.requestClose(), false);
  assert.equal(win.destroyed, true);
});

test('a window closed before the tray exists is not intercepted', () => {
  const { open } = setup();
  const win = open('early'); // ready has not run yet
  assert.equal(win.requestClose(), false);
});

test('an unreadable icon is reported but the tray is still created', () => {
  const { calls, start } = setup({ emptyIcon: true });
  start();
  assert.equal(calls.trays.length, 1);
  assert.ok(calls.logs.some((message) => /icon unreadable/.test(message)));
});

// The order matters: the hook has to run before app.exit(), which ends the process.
function recordedQuit(extra = {}) {
  const order = [];
  const setupResult = setup({ ...extra, onQuit: () => { order.push('hook'); if (extra.hookThrows) throw new Error('hook failed'); } });
  const originalExit = setupResult.app.exit;
  setupResult.app.exit = (code) => { order.push('exit'); originalExit(code); };
  return { ...setupResult, order };
}

test('quit runs the hook before the process exits', async () => {
  const { calls, start, open, order } = recordedQuit();
  start();
  open('main');
  calls.menus[0].find((item) => item.label === '退出应用').click();
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(order, ['hook', 'exit']);
});

test('confirming the question runs the hook before the exit', async () => {
  const { calls, start, open, order } = recordedQuit({ owned: { pid: 42 }, dialogResponse: 1 });
  start();
  open('main');
  calls.menus[0].find((item) => item.label === '退出应用').click();
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(order, ['hook', 'exit']);
});

test('cancelling the question runs no hook and keeps the app', async () => {
  const { calls, start, open, order } = recordedQuit({ owned: { pid: 42 }, dialogResponse: 0 });
  start();
  open('main');
  calls.menus[0].find((item) => item.label === '退出应用').click();
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(order, []);
  assert.deepEqual(calls.exit, []);
});

test('a second click while the question is open runs the hook and exits', async () => {
  const { calls, start, open, order } = recordedQuit({ owned: { pid: 42 }, dialogHeld: true });
  start();
  open('main');
  const quit = () => calls.menus[0].find((entry) => entry.label === '退出应用').click();
  quit();
  await new Promise((resolve) => setImmediate(resolve));
  quit();
  assert.deepEqual(order, ['hook', 'exit']);
});

test('a hook that fails does not keep the app from exiting', async () => {
  const { calls, start, open, order } = recordedQuit({ hookThrows: true });
  start();
  open('main');
  calls.menus[0].find((item) => item.label === '退出应用').click();
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(order, ['hook', 'exit']);
  assert.ok(calls.logs.some((message) => /quit hook failed/.test(message)));
});

test('quit without a hook exits as before', async () => {
  const { calls, start, open } = setup();
  start();
  open('main');
  calls.menus[0].find((item) => item.label === '退出应用').click();
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(calls.exit, [0]);
});
