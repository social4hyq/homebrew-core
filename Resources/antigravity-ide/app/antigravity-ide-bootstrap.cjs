// Antigravity IDE OHOS shell. The official app is a VS Code fork whose main
// entry is ESM; it is loaded after mapping openharmony to the linux branch that
// the vendor code expects. The vendor app is closed source and never shipped
// in the bottle.
const path = require('path');
const { pathToFileURL } = require('url');
const { app } = require('electron');

// Vendor platform checks are linux-only; electron-ohos reports openharmony.
Object.defineProperty(process, 'platform', { value: 'linux', configurable: true });

app.commandLine.appendSwitch('no-sandbox');
app.commandLine.appendSwitch('disable-gpu');

const main = path.join(__dirname, 'vendor', 'out', 'main.js');
import(pathToFileURL(main).href).catch((error) => {
  try {
    require('node:fs').appendFileSync(
      path.join(require('node:os').homedir(), 'antigravity-ide-shell.log'),
      `${new Date().toISOString()} ${error && error.stack ? error.stack : error}\n`
    );
  } catch (_) {
    // logging must never prevent startup
  }
  app.exit(2);
});
