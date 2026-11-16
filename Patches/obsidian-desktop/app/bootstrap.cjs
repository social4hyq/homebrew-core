'use strict';
// Generic host for an unmodified Obsidian app package on the HarmonyOS
// Electron runtime (Electron 40 / Chromium 144).
//
// The vendor ships two app packages:
//   resources/app.asar      -> bootstrap (index/main, @electron/remote, updater)
//   resources/obsidian.asar -> the real app, exports function(asarPath, updateEvents)
// This file reproduces only the host contract that app.asar provides; the app
// package itself is never modified.
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { EventEmitter } = require('node:events');
const electron = require('electron');
const { app, dialog, protocol } = electron;

function log(msg) {
  console.log('[OBSIDIAN-HOST] ' + msg);
}

// Devtools for support: ship a `debug-devtools` file next to this host to open
// the CDP port (never present in a release payload).
// Obsidian gates its command line interface on argv0 being "obsidian"; the
// OHOS runtime launches this process from resfile/electron and argv0 is
// read-only, so rewrite what `path.basename(process.argv0)` reports.
try {
  Object.defineProperty(process, 'argv0', { value: 'obsidian', configurable: true });
} catch {
  // read-only: patched below
}
const nodePath = require('node:path');
if (nodePath.basename(process.argv0) !== 'obsidian') {
  const originalBasename = nodePath.basename;
  nodePath.basename = function patchedBasename(target, ext) {
    const result = originalBasename.call(this, target, ext);
    return result === 'electron' ? 'obsidian' : result;
  };
}

// Obsidian listens on $XDG_RUNTIME_DIR/.obsidian-cli.sock. Creating a socket in
// the user's home is denied (EPERM) even with the ACLs, so keep it inside the
// app sandbox and bridge it to loopback TCP for the host side below.
const cliRuntimeDir = path.join(app.getPath('userData'), 'runtime');
try {
  fs.mkdirSync(cliRuntimeDir, { recursive: true });
  process.env.XDG_RUNTIME_DIR = cliRuntimeDir;
  log('cli runtime dir -> ' + cliRuntimeDir);
} catch (error) {
  log('cli runtime dir unavailable: ' + String((error && error.message) || error));
}

const debug = fs.existsSync(path.join(__dirname, 'debug-devtools'));
if (debug) {
  process.env.OBSIDIAN_HOST_DEBUG = '1';
  app.commandLine.appendSwitch('remote-debugging-port', '9333');
}

// 1. Custom scheme, before app ready. main.js filters webRequest on app://*/*
//    and the renderer is launched with --standard-schemes=app etc.
protocol.registerSchemesAsPrivileged([{
  scheme: 'app',
  privileges: {
    standard: true,
    secure: true,
    supportFetchAPI: true,
    stream: true,
    codeCache: true,
    corsEnabled: true,
  },
}]);

// 2. @electron/remote: removed from Electron core in v14; Obsidian 1.15 still
//    calls electron.remote.enable() and the renderer requires the package.
try {
  const remoteMain = require('@electron/remote/main');
  remoteMain.initialize();
  electron.remote = remoteMain;
  log('@electron/remote ready');
} catch (error) {
  log('@electron/remote missing: ' + String((error && error.message) || error));
}

// 3. Documents dir. Obsidian's default vault is documents/Obsidian Vault. The
//    HAP sandbox cannot write the host Documents directory unless the ACL
//    variant is installed, so probe it and fall back to a sandbox Documents
//    dir when the app is running strong-sandboxed.
function writableDir(dir) {
  try {
    fs.mkdirSync(dir, { recursive: true });
    const probe = path.join(dir, `.write-probe-${process.pid}`);
    fs.writeFileSync(probe, '');
    fs.unlinkSync(probe);
    return true;
  } catch {
    return false;
  }
}

try {
  // The ACL variant can write the user's home, but some system-managed
  // subdirectories (Documents is owned by file_manager) still reject writes
  // with EPERM. Probe for real instead of trusting access(W_OK).
  const candidates = [
    app.getPath('documents'),
    path.join(app.getPath('home'), 'Obsidian'),
    path.join(app.getPath('userData'), 'Documents'),
  ];
  const selected = candidates.find((dir) => dir && writableDir(dir));
  if (!selected) throw new Error('no writable documents directory');
  app.setPath('documents', selected);
  log('documents -> ' + selected);
} catch (error) {
  log('documents decision failed: ' + String((error && error.message) || error));
}

// Obsidian parses process.versions.electron with a strict dotted-number
// parser to decide whether to nag about reinstalling. The runtime reports
// "v40.0.1-release" in renderers, parseInt("v40") is NaN, and the app therefore
// treats the runtime as too old. index.html loads app.js after a
// requestAnimationFrame + setTimeout, so patching the value on dom-ready lands
// before the bundle evaluates.
const versionPatch = `(() => {
  const parse = (value) => {
    const match = /^v?(\\d+)\\.(\\d+)\\.(\\d+)/.exec(String(value || ''));
    return match ? match.slice(1, 4).join('.') : null;
  };
  const clean = parse(process.versions.electron);
  if (!clean || clean === process.versions.electron) return;
  try { process.versions.electron = clean; } catch (error) {}
  if (process.versions.electron !== clean) {
    try {
      Object.defineProperty(process.versions, 'electron', {
        value: clean, configurable: true, enumerable: true, writable: true,
      });
    } catch (error) {}
  }
  console.log('[OBSIDIAN-HOST] renderer electron version -> ' + process.versions.electron);
})()`;

app.on('web-contents-created', (_event, contents) => {
  contents.on('dom-ready', () => {
    contents.executeJavaScript(versionPatch).catch(() => {});
  });
});

// The runtime's version string makes Obsidian believe it is too old and nag
// about reinstalling. Desktop updates are the package manager's job here, so
// answer the app's `disable-update` query with true: the banner is gated on
// that answer, and the renderer-side version patch above is only a bonus.
function takeOverUpdateChannel() {
  try {
    const { ipcMain } = electron;
    ipcMain.removeAllListeners('disable-update');
    ipcMain.on('disable-update', (event) => {
      event.returnValue = true;
    });
    log('update channel taken over');
  } catch (error) {
    log('update channel takeover failed: ' + String((error && error.message) || error));
  }
}

// Cold-start deep links land in <userData>/incoming-uris.txt (written by the
// ArkTS ability) because the runtime does not forward want.uri to Electron on
// the first launch. Replay them into Obsidian's URI handler once the CLI socket
// is listening, then truncate the file.
function replayPendingUris() {
  const pendingPath = path.join(app.getPath('userData'), 'incoming-uris.txt');
  let raw = '';
  try {
    raw = fs.readFileSync(pendingPath, 'utf8');
  } catch {
    return;
  }
  const uris = raw.split('\n').map((line) => line.trim()).filter(Boolean);
  if (uris.length === 0) return;
  try { fs.unlinkSync(pendingPath); } catch {}
  const attempt = (index) => {
    if (index >= uris.length) return;
    const socketPath = path.join(cliRuntimeDir, '.obsidian-cli.sock');
    if (!fs.existsSync(socketPath)) {
      setTimeout(() => attempt(index), 100);
      return;
    }
    routeObsidianUri(uris[index]);
    setTimeout(() => attempt(index + 1), 100);
  };
  setTimeout(() => attempt(0), 100);
}

// Frameless windows ("frame": "hidden", Obsidian's default) get no window
// controls because the custom title bar has none on this platform. Ask the
// runtime for the floating caption buttons instead and reserve their corner in
// the tab strip so they do not cover Obsidian's own buttons.
const CAPTION_PADDING_CSS =
  "body.is-hidden-frameless .workspace-tab-header-container { padding-right: 140px !important; }";

function readFrameStyle() {
  try {
    const config = JSON.parse(fs.readFileSync(path.join(app.getPath('userData'), 'obsidian.json'), 'utf8'));
    return config.frame || 'hidden';
  } catch {
    return 'hidden';
  }
}

function setupFramelessControls(win) {
  try {
    if (readFrameStyle() !== 'hidden') return;
    // Obsidian draws its own minimize/maximize/close buttons for a frameless
    // window, but only wires the Linux layout that shows them when the body has
    // the mod-linux class, which it derives from process.platform. The runtime
    // reports "openharmony", so add the class ourselves and reserve the button
    // corner in the tab strip. No second set of native buttons.
    win.webContents.on('dom-ready', () => {
      win.webContents
        .executeJavaScript("document.body.classList.add('mod-linux')")
        .catch(() => {});
      win.webContents.insertCSS(CAPTION_PADDING_CSS).catch(() => {});
      log('frameless: obsidian titlebar buttons enabled');
    });
  } catch (error) {
    log('frameless controls failed: ' + String((error && error.message) || error));
  }
}

app.on('browser-window-created', (_event, win) => setupFramelessControls(win));

// In-app obsidian:// links are handed to the OS (shell.openExternal) and expect
// a registered handler to relaunch the app. There is none on HarmonyOS, so feed
// the URL back into the app's own URI handler over its CLI socket instead.
function routeObsidianUri(url) {
  try {
    const net = require('node:net');
    const socketPath = path.join(cliRuntimeDir, '.obsidian-cli.sock');
    const client = net.connect(socketPath, () => {
      client.write(`${JSON.stringify({ argv: ['obsidian', url], tty: false, cwd: process.cwd() })}\n`);
    });
    client.on('error', (error) => log('obsidian:// route failed: ' + String(error.message)));
    client.resume();
  } catch (error) {
    log('obsidian:// route failed: ' + String((error && error.message) || error));
  }
}

try {
  const shell = require('electron').shell;
  const originalOpenExternal = shell.openExternal.bind(shell);
  shell.openExternal = (url, options) => {
    if (typeof url === 'string' && url.startsWith('obsidian://')) {
      log('routing in-app URI ' + url);
      routeObsidianUri(url);
      return Promise.resolve();
    }
    return originalOpenExternal(url, options);
  };
} catch (error) {
  log('openExternal hook failed: ' + String((error && error.message) || error));
}

// Bridge Obsidian's CLI socket (sandbox-only) to loopback TCP with a token, so
// the host-side `obsidian-desktop cli` can drive the running app.
let cliConfigPath = null;
function startCliBridge() {
  try {
    const net = require('node:net');
    const crypto = require('node:crypto');
    const token = crypto.randomBytes(16).toString('hex');
    const socketPath = path.join(cliRuntimeDir, '.obsidian-cli.sock');
    const server = net.createServer((client) => {
      client.setNoDelay(true);
      let buffered = '';
      let authed = false;
      let upstream = null;
      let pending = '';
      const forward = (chunk) => {
        if (upstream) upstream.write(chunk);
        else pending += chunk;
      };
      const onData = (chunk) => {
        if (authed) {
          forward(chunk);
          return;
        }
        buffered += chunk.toString('utf8');
        const newline = buffered.indexOf('\n');
        if (newline === -1) return;
        if (buffered.slice(0, newline) !== token) {
          log('cli bridge: auth failed');
          client.destroy();
          return;
        }
        const rest = buffered.slice(newline + 1);
        buffered = '';
        authed = true;
        client.removeListener('data', onData);
        client.on('data', forward);
        if (rest) forward(rest);
        upstream = net.connect(socketPath, () => {
          if (pending) {
            upstream.write(pending);
            pending = '';
          }
        });
        upstream.on('error', (error) => {
          log('cli bridge upstream error: ' + String(error.message));
          client.destroy();
        });
        upstream.on('end', () => client.end());
        client.on('error', () => upstream.destroy());
        upstream.pipe(client);
      };
      client.on('data', onData);
      client.on('error', () => {});
    });
    server.on('error', (error) => log('cli bridge error: ' + String(error.message)));
    server.listen(0, '127.0.0.1', () => {
      const { port } = server.address();
      const config = { port, token, pid: process.pid };
      cliConfigPath = path.join(os.homedir(), '.cache', 'obsidian-desktop', 'cli.json');
      try {
        fs.mkdirSync(path.dirname(cliConfigPath), { recursive: true });
        fs.writeFileSync(cliConfigPath, JSON.stringify(config), { mode: 0o600 });
        log('cli bridge on 127.0.0.1:' + port);
      } catch (error) {
        log('cli bridge config not written: ' + String(error.message));
        cliConfigPath = null;
      }
    });
  } catch (error) {
    log('cli bridge failed: ' + String((error && error.message) || error));
  }
}
app.whenReady().then(() => {
  startCliBridge();
  replayPendingUris();
});
app.on('quit', () => {
  if (!cliConfigPath) return;
  try { fs.unlinkSync(cliConfigPath); } catch {}
});

const updateEvents = new EventEmitter();
const asarPath = path.join(__dirname, 'obsidian.asar');

// Desktop self-update is the package manager's job here. Keep the UI calm by
// reporting our own version as the newest one and closing the check window.
const appVersion = require('./package.json').version;
updateEvents.on('check', () => {
  updateEvents.emit('latest-public-version', appVersion);
  updateEvents.emit('check-end');
});

app.on('web-contents-created', (_event, contents) => {
  contents.on('did-finish-load', () => log('loaded ' + contents.getURL()));
  contents.on('console-message', (_e, level, message, line, source) =>
    log(`console[${level}] ${message} (${source}:${line})`));
  contents.on('did-fail-load', (_e, code, desc, url, main) =>
    log(`did-fail-load ${code} ${desc} ${url} main=${main}`));
  contents.on('render-process-gone', (_e, details) =>
    log('render-process-gone ' + JSON.stringify(details)));
});

log(`electron ${process.versions.electron} chrome ${process.versions.chrome} ` +
    `node ${process.versions.node} platform ${process.platform} app ${appVersion}`);

try {
  const start = require(path.join(asarPath, 'main.js'));
  if (typeof start !== 'function') {
    throw new Error('obsidian.asar/main.js exported ' + typeof start + ', expected function');
  }
  start(asarPath, updateEvents);
  updateEvents.emit('latest-public-version', appVersion);
  takeOverUpdateChannel();
  log('app started');
} catch (error) {
  log('BOOT FAILED: ' + (error && error.stack ? error.stack : String(error)));
  app.whenReady().then(() => {
    dialog.showErrorBox('Obsidian failed to start', String(error && error.stack ? error.stack : error));
  });
}
