'use strict';

const { app, BrowserWindow } = require('electron');
const { spawn } = require('node:child_process');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const { isServerUrl, createUrlCollector } = require('./startup.cjs');

let config = { port: 0 };
try {
  Object.assign(config, JSON.parse(fs.readFileSync(path.join(__dirname, 'config.json'), 'utf8')));
} catch (error) {
  console.error('DSH_DESKTOP config unreadable: ' + String(error));
}

const configured = Number.isInteger(config.port) && config.port > 0;
const canAutoStart = configured && typeof config.dsh === 'string' && config.dsh.length > 0;
const host = config.host && typeof config.host === 'object' ? config.host : {};
const stateDir = typeof host.home === 'string' && host.home.length > 0
  ? path.join(host.home, '.config', 'deepseek-harness-desktop')
  : null;
const urlFile = stateDir ? path.join(stateDir, 'web.url') : null;

let serveChild = null;
let serveSpawnError = '';
let serverUrl = '';

function validServerUrl(value) {
  return isServerUrl(value, config.port);
}

function readServerUrl() {
  if (validServerUrl(serverUrl)) return serverUrl;
  if (!urlFile) return '';
  try {
    const value = fs.readFileSync(urlFile, 'utf8').trim();
    if (validServerUrl(value)) return value;
  } catch {}
  return '';
}

function serverUp(url, timeoutMs) {
  return new Promise((resolve) => {
    if (!validServerUrl(url)) return resolve(false);
    const req = http.get(url, { timeout: timeoutMs, agent: false }, (res) => {
      res.resume();
      resolve(res.statusCode === 200 || res.statusCode === 303);
    });
    req.on('timeout', () => { req.destroy(); resolve(false); });
    req.on('error', () => resolve(false));
  });
}

function serveLogPath() {
  if (typeof host.home === 'string' && host.home.length > 0) {
    try {
      const dir = path.join(host.home, '.cache', 'deepseek-harness-desktop');
      fs.mkdirSync(dir, { recursive: true });
      return path.join(dir, 'serve.log');
    } catch (error) {
      console.error('DSH_DESKTOP host log dir unavailable: ' + String(error));
    }
  }
  return path.join(app.getPath('userData'), 'dsh-web.log');
}

function rememberServerUrl(value) {
  serverUrl = value;
  if (!urlFile) return;
  try {
    fs.mkdirSync(path.dirname(urlFile), { recursive: true, mode: 0o700 });
    fs.writeFileSync(urlFile, value + '\n', { mode: 0o600 });
  } catch (error) {
    console.error('DSH_DESKTOP cannot save web URL: ' + String(error));
  }
}

function spawnServer() {
  if (!canAutoStart || serveChild) return;
  const env = Object.assign({}, process.env);
  if (typeof host.home === 'string') env.HOME = host.home;
  if (typeof host.path === 'string') env.PATH = host.path;
  for (const [key, envKey] of [['xdgConfig', 'XDG_CONFIG_HOME'], ['xdgData', 'XDG_DATA_HOME'], ['xdgState', 'XDG_STATE_HOME']]) {
    if (typeof host[key] !== 'string') continue;
    if (host[key]) env[envKey] = host[key];
    else delete env[envKey];
  }
  env.TMPDIR = app.getPath('temp');
  if (!env.NODE_COMPILE_CACHE && !env.NODE_DISABLE_COMPILE_CACHE) {
    env.NODE_COMPILE_CACHE = path.join(app.getPath('userData'), 'node-compile-cache');
  }

  let logFd;
  const logPath = serveLogPath();
  try {
    logFd = fs.openSync(logPath, 'a', 0o600);
    fs.writeSync(logFd, `\n[shell] ${new Date().toISOString()} spawn ${config.dsh} web ` +
      `HOME=${env.HOME} TMPDIR=${env.TMPDIR}\n`);
  } catch (error) {
    console.error('DSH_DESKTOP cannot open serve log: ' + String(error));
    logFd = undefined;
  }

  try {
    serveChild = spawn(config.dsh, ['web', '--host', '127.0.0.1', '--no-open', '--port', String(config.port)], {
      env,
      cwd: typeof host.home === 'string' && host.home.length > 0 ? host.home : undefined,
      stdio: ['ignore', 'pipe', 'pipe'],
    });
  } catch (error) {
    if (logFd !== undefined) { fs.closeSync(logFd); logFd = undefined; }
    serveSpawnError = String(error);
    console.error('DSH_DESKTOP spawn failed: ' + serveSpawnError);
    return;
  }

  const stdoutUrls = createUrlCollector(config.port, rememberServerUrl);
  const stderrUrls = createUrlCollector(config.port, rememberServerUrl);
  for (const [stream, collect] of [[serveChild.stdout, stdoutUrls], [serveChild.stderr, stderrUrls]]) {
    stream.on('data', (chunk) => {
      if (logFd !== undefined) fs.writeSync(logFd, chunk);
      collect(chunk);
    });
  }
  serveChild.once('close', () => {
    if (logFd !== undefined) { fs.closeSync(logFd); logFd = undefined; }
  });
  serveChild.on('error', (error) => {
    serveSpawnError = String(error);
    console.error('DSH_DESKTOP spawn error: ' + serveSpawnError);
  });
  serveChild.on('exit', () => {
    serveChild = null;
    serverUrl = '';
  });
}

function stopServer() {
  if (!serveChild) return;
  try { serveChild.kill(); } catch (error) { console.error('DSH_DESKTOP kill failed: ' + String(error)); }
  serveChild = null;
}

async function drive(win) {
  if (!configured) {
    await win.loadFile(path.join(__dirname, 'waiting.html'), { hash: 'not-configured' });
    return;
  }

  let waiting = false;
  let lastSpawnAttempt = 0;
  for (;;) {
    if (win.isDestroyed()) return;
    const url = readServerUrl();
    if (await serverUp(url, 2000)) {
      await win.loadURL(url);
      return;
    }
    if (canAutoStart && !serveChild && Date.now() - lastSpawnAttempt > 10000) {
      lastSpawnAttempt = Date.now();
      spawnServer();
    }
    if (!waiting) {
      waiting = true;
      await win.loadFile(path.join(__dirname, 'waiting.html'), { hash: serveSpawnError ? 'spawn-failed' : 'waiting' });
    }
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
}

app.whenReady().then(() => {
  const win = new BrowserWindow({
    backgroundColor: "#11141b",
    width: 1280,
    height: 800,
    autoHideMenuBar: true,
    webPreferences: { contextIsolation: true, sandbox: true, nodeIntegration: false },
  });
  win.setWindowButtonVisibility(true);
  win.webContents.on('render-process-gone', (_event, details) => {
    console.error('DSH_DESKTOP_RENDER_EXIT ' + JSON.stringify(details));
  });
  drive(win).catch((error) => console.error('DSH_DESKTOP drive failed: ' + String(error)));
}).catch((error) => {
  console.error(error);
  app.exit(1);
});

app.on('before-quit', stopServer);
app.on('window-all-closed', () => {
  stopServer();
  app.quit();
});
