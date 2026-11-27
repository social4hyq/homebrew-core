'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const Module = require('node:module');
const path = require('node:path');
const test = require('node:test');

const appDir = path.join(__dirname, '..', 'app');
const trayPath = path.join(appDir, 'tray.cjs');

// Load tray.cjs against a fake `electron` and return what it did to it.
function loadTray() {
  const calls = { setContextMenu: [], exit: [], templates: [] };
  const fake = {
    app: { exit: (code) => calls.exit.push(code) },
    Menu: { buildFromTemplate: (template) => { calls.templates.push(template); return { template }; } },
    Tray: class {
      setToolTip() {}
      on() {}
      setContextMenu(menu) { calls.setContextMenu.push(menu); }
    },
    nativeImage: { createFromPath: () => ({ isEmpty: () => false }) },
  };
  const original = Module._load;
  Module._load = function load(request, ...rest) {
    return request === 'electron' ? fake : original.call(this, request, ...rest);
  };
  delete require.cache[trayPath];
  try {
    return { tray: require(trayPath), calls };
  } finally {
    Module._load = original;
    delete require.cache[trayPath];
  }
}

const codeLines = (file) => fs.readFileSync(file, 'utf8').split('\n').filter((line) => !/^\s*\/\//.test(line));

test('create hands the status bar exactly one menu', () => {
  const { tray, calls } = loadTray();
  tray.create({ onQuitRequest: () => {} });
  assert.equal(calls.setContextMenu.length, 1);
  assert.equal(calls.templates.length, 1);
});

test('the menu keeps the shared layout: show, separator, quit', () => {
  const { tray, calls } = loadTray();
  tray.create({ onQuitRequest: () => {} });
  const items = calls.templates[0];
  assert.deepEqual(items.map((item) => item.label || item.type), ['显示窗口', 'separator', '退出应用']);
});

test('a restart item goes before the separator when asked for', () => {
  const { tray, calls } = loadTray();
  tray.create({ onRestartBackend: () => {}, onQuitRequest: () => {} });
  assert.deepEqual(calls.templates[0].map((item) => item.label || item.type),
    ['显示窗口', '重新启动后端', 'separator', '退出应用']);
});

test('with onQuitRequest the quit item calls it and neither exits nor marks quitting', () => {
  const { tray, calls } = loadTray();
  let asked = 0;
  tray.create({ onQuitRequest: () => { asked += 1; } });
  calls.templates[0][2].click();
  assert.equal(asked, 1);
  assert.deepEqual(calls.exit, []);
  assert.equal(tray.isQuitting(), false);
});

test('without onQuitRequest the quit item behaves as in the shared tray', () => {
  const { tray, calls } = loadTray();
  let hooked = 0;
  tray.create({ onQuit: () => { hooked += 1; } });
  calls.templates[0][2].click();
  assert.equal(hooked, 1);
  assert.deepEqual(calls.exit, [0]);
  assert.equal(tray.isQuitting(), true);
});

test('a failing onQuit hook still exits', () => {
  const { tray, calls } = loadTray();
  tray.create({ onQuit: () => { throw new Error('boom'); } });
  const original = console.error;
  console.error = () => {};
  try {
    calls.templates[0][2].click();
  } finally {
    console.error = original;
  }
  assert.deepEqual(calls.exit, [0]);
});

test('only tray.cjs sets the context menu, and only once', () => {
  const inTray = codeLines(trayPath).filter((line) => line.includes('setContextMenu('));
  assert.equal(inTray.length, 1);
  const inMain = codeLines(path.join(appDir, 'main.cjs')).filter((line) => line.includes('setContextMenu('));
  assert.deepEqual(inMain, []);
});
