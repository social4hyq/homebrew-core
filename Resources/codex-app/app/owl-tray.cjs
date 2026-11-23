'use strict';

// Keeps the app resident in the system tray, like the other HAP apps of this tap.
//
// electron-ohos implements Electron's Tray on the HarmonyOS status bar service, and
// BrowserWindow.hide() only keeps the Electron process alive while a status bar item
// exists, so the tray is created before the first window and closing the last window
// hides it instead. The shell's ArkTS windowStageClose handler (stage-ohos-shell.sh)
// does the same for the ability; without both, the X button ends the process. The
// official app's own tray never appears on this platform.
//
// The tray menu restores the window (the same process, nothing new is started) and
// quits. When this app started the shared codex app-server (owl-share.cjs), quitting
// ends it, so a terminal attached to it loses it: the menu asks first.
const path = require('node:path');

const MESSAGE = '退出应用会同时结束由本应用启动的共享 Codex 服务，终端里连接到它的 codex 会断开。' +
  '要让服务独立于应用运行，请先在终端里运行 codex-app serve（应用重启后会直接使用它）。';

// electron  the module (stubbed in tests)
// options   { iconPath, ownedServer() -> truthy while this app's shared server runs, log }
function install(electron, options = {}) {
  const { app, BrowserWindow, Menu, Tray, nativeImage, dialog } = electron;
  const log = options.log || ((message) => console.error(message));
  let tray = null;
  let quitting = false;
  let confirming = false;
  let hidden = null;

  const windows = () => BrowserWindow.getAllWindows().filter((win) => !win.isDestroyed());

  function showWindow() {
    const target = hidden && !hidden.isDestroyed() ? hidden : (windows().find((win) => !win.isVisible()) || windows()[0]);
    if (!target) return;
    if (target.isMinimized()) target.restore();
    target.show();
    target.focus();
  }

  // The window that was hidden to the tray is the one to bring back.
  app.on('browser-window-created', (_event, win) => {
    win.on('close', (event) => {
      if (quitting || !tray) return;
      // Another window is open: this one really closes.
      if (windows().some((other) => other !== win && other.isVisible())) return;
      event.preventDefault();
      hidden = win;
      win.hide();
    });
  });

  async function quit() {
    // A second click while the question is open means "quit anyway", and keeps the
    // menu from sticking if the dialog never shows.
    if (confirming) {
      quitting = true;
      app.exit(0);
      return;
    }
    confirming = true;
    try {
      if (options.ownedServer && options.ownedServer()) {
        let proceed = true;
        try {
          showWindow();
          const parent = windows().find((win) => win.isVisible());
          const { response } = await dialog.showMessageBox(parent, {
            type: 'warning',
            title: '退出 Codex',
            message: '本应用启动了共享的 Codex 服务',
            detail: MESSAGE,
            buttons: ['取消', '仍然退出'],
            defaultId: 0,
            cancelId: 0,
          });
          proceed = response === 1;
        } catch (error) {
          log('OWL_TRAY quit dialog failed: ' + String(error));
        }
        if (!proceed) return;
      }
      quitting = true;
      // The ArkTS close handler keeps the ability alive, so app.quit() would be vetoed.
      app.exit(0);
    } finally {
      confirming = false;
    }
  }

  app.whenReady().then(() => {
    try {
      const icon = nativeImage.createFromPath(options.iconPath || path.join(__dirname, 'tray-icon.png'));
      if (icon.isEmpty()) log('OWL_TRAY icon unreadable ' + options.iconPath);
      const created = new Tray(icon);
      created.setToolTip('ChatGPT');
      created.on('click', showWindow);
      // One menu, set once: a second setContextMenu a moment later is sometimes refused.
      created.setContextMenu(Menu.buildFromTemplate([
        { label: '显示窗口', click: showWindow },
        { type: 'separator' },
        { label: '退出应用', click: () => { void quit(); } },
      ]));
      tray = created;
    } catch (error) {
      tray = null;
      log('OWL_TRAY tray unavailable: ' + String(error && error.message));
    }
  });

  return { showWindow, quit, isQuitting: () => quitting, hasTray: () => tray !== null };
}

module.exports = { install };
