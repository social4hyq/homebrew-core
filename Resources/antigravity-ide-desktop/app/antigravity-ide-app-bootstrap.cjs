// Antigravity IDE OHOS shell. The official app is a VS Code fork whose main
// entry is ESM; it is loaded after presenting a "linux" platform to the vendor
// code (without disturbing electron-ohos, which needs the real platform).
// The vendor app is closed source and never shipped in the bottle.
const path = require('path');
const { pathToFileURL } = require('url');
const { app } = require('electron');

// VS Code reads platform via globalThis.vscode.process when present (see its
// platform detection in out/main.js). Present a Proxy that reports "linux"
// while the real process.platform stays "openharmony" for electron-ohos.
const realProcess = process;
const platformProxy = new Proxy(realProcess, {
  get(target, key) {
    if (key === 'platform') return 'linux';
    const value = target[key];
    return typeof value === 'function' ? value.bind(target) : value;
  },
});
globalThis.vscode = globalThis.vscode || {};
globalThis.vscode.process = platformProxy;

app.commandLine.appendSwitch('no-sandbox');
app.commandLine.appendSwitch('disable-gpu');

const main = path.join(__dirname, 'vendor', 'out', 'main.js');
import(pathToFileURL(main).href).catch((error) => {
  try {
    require('node:fs').appendFileSync(
      path.join(require('node:os').homedir(), 'antigravity-ide-app-shell.log'),
      `${new Date().toISOString()} ${error && error.stack ? error.stack : error}\n`
    );
  } catch (_) {
    // logging must never prevent startup
  }
  app.exit(2);
});
