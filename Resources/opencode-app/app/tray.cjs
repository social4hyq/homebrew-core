'use strict';
// System-tray residency for the OpenHarmony Electron shell.
//
// electron-ohos implements Electron's Tray API on top of the HarmonyOS status
// bar service (StatusBarExtensionKit), and BrowserWindow.hide() only keeps the
// Electron process alive while a status bar item exists -- hideAbility() is
// rejected with 16000067 and falls back to minimize() otherwise. So the tray
// must be created before the first window, and closing a window must hide it
// rather than destroy it.
//
// opencode-app's copy of Resources/_shared/electron-shell/tray.cjs. The only
// difference is `onQuitRequest`: when given, the "退出应用" item calls it and
// leaves quitting (and `app.exit`) to it, so the caller can ask first. The
// context menu is set exactly once, inside create(): electron-ohos hands a
// menu to the status bar service asynchronously, and a second setContextMenu()
// a few milliseconds later was sometimes refused ("StatusBarManager::
// SetContextMenu Failed"), which left the engine with the first menu's item
// codes while the JS side only knew the second one, so a click did nothing.
const { app, Menu, Tray, nativeImage } = require('electron');
const path = require('node:path');

let tray = null;
let target = null;
let quitting = false;

function showWindow() {
  if (!target || target.isDestroyed()) return;
  if (target.isMinimized()) target.restore();
  target.show();
  target.focus();
}

function create(options = {}) {
  const iconPath = options.iconPath || path.join(__dirname, 'tray-icon.png');
  const image = nativeImage.createFromPath(iconPath);
  if (image.isEmpty()) console.error('TRAY_ICON_UNREADABLE ' + iconPath);
  tray = new Tray(image);
  if (options.tooltip) tray.setToolTip(options.tooltip);
  tray.on('click', showWindow);

  const items = [{ label: options.showLabel || '显示窗口', click: showWindow }];
  if (typeof options.onRestartBackend === 'function') {
    items.push({ label: options.restartLabel || '重新启动后端', click: options.onRestartBackend });
  }
  items.push({ type: 'separator' });
  const quitNow = () => {
    quitting = true;
    if (typeof options.onQuit === 'function') {
      try {
        options.onQuit();
      } catch (error) {
        console.error('TRAY_QUIT_HOOK_FAILED ' + String(error));
      }
    }
    // The shell's ArkTS windowStageClose handler refuses to close the window
    // so the app stays resident, so a regular app.quit() would be vetoed.
    // Exit the process directly instead.
    app.exit(0);
  };
  items.push({
    label: options.quitLabel || '退出应用',
    click: typeof options.onQuitRequest === 'function' ? options.onQuitRequest : quitNow,
  });
  tray.setContextMenu(Menu.buildFromTemplate(items));
  return tray;
}

function attach(window) {
  target = window;
  window.on('close', (event) => {
    if (quitting) return;
    event.preventDefault();
    window.hide();
  });
}

function destroy() {
  if (!tray) return;
  try {
    tray.destroy();
  } catch (error) {
    console.error('TRAY_DESTROY_FAILED ' + String(error));
  }
  tray = null;
}

module.exports = { create, attach, showWindow, destroy, isQuitting: () => quitting };
