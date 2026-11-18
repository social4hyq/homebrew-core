const { app, BrowserWindow, shell } = require("electron");
const { spawn } = require("node:child_process");
const { randomBytes } = require("node:crypto");
const { readFileSync } = require("node:fs");
const { join } = require("node:path");
const { createInterface } = require("node:readline");
const { pathToFileURL } = require("node:url");

const config = JSON.parse(readFileSync(join(__dirname, "config.json"), "utf8"));
const connect = pathToFileURL(join(__dirname, "connect.html")).href;
let backend;
let origin;

function readyLink(line, key) {
  const match = /magpie web on (http:\/\/127\.0\.0\.1:[1-9]\d{0,4}\/\?k=[a-f0-9]{64})\s*$/.exec(
    line.replace(/\x1b\[[0-9;]*m/g, ""),
  );
  if (!match) return;
  try {
    const url = new URL(match[1]);
    if (url.searchParams.get("k") === key) return url;
  } catch {
    // Ignore a malformed address.
  }
}

function show(win, mode) {
  if (!win.isDestroyed()) void win.loadURL(connect + "#" + mode).catch(() => {});
}

function start(win) {
  if (!config.backend) return show(win, "manual");

  show(win, "starting");
  const key = randomBytes(32).toString("hex");
  const env = {
    ...process.env,
    ...config.host,
    TMPDIR: app.getPath("temp"),
    MAGPIE_WEB_KEY: key,
    NO_COLOR: "1",
  };
  for (const name of ["XDG_RUNTIME_DIR", "XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_STATE_HOME", "XDG_CACHE_HOME"]) {
    if (!config.host[name]) delete env[name];
  }
  backend = spawn(config.backend, ["serve", "--web=127.0.0.1:0"], {
    cwd: env.HOME,
    env,
    stdio: ["ignore", "pipe", "ignore"],
  });
  const child = backend;
  let unavailable = false;
  const failed = () => {
    if (unavailable) return;
    unavailable = true;
    clearTimeout(timer);
    origin = undefined;
    show(win, "failed");
  };
  const timer = setTimeout(() => { child.kill(); failed(); }, 30_000);
  child.once("error", failed);
  child.once("exit", failed);
  const output = createInterface({ input: child.stdout });
  output.on("line", line => {
    if (unavailable || origin || win.isDestroyed()) return;
    const url = readyLink(line, key);
    if (!url) return;
    clearTimeout(timer);
    origin = url.origin;
    void win.loadURL(url.href).catch(() => { child.kill(); failed(); });
  });
}

if (!app.requestSingleInstanceLock()) {
  app.quit();
} else {
  let win;
  app.on("second-instance", () => {
    if (win && !win.isDestroyed()) {
      win.show();
      win.focus();
    }
  });
  app.whenReady().then(() => {
    win = new BrowserWindow({
      title: "Magpie",
      width: 1100,
      height: 760,
      webPreferences: { nodeIntegration: false, contextIsolation: true, sandbox: true },
    });
    const session = win.webContents.session;
    session.setPermissionRequestHandler((_contents, _permission, callback) => callback(false));
    session.setPermissionCheckHandler(() => false);
    win.webContents.on("will-navigate", (event, target) => {
      const url = new URL(target);
      if (origin && url.origin === origin) return;
      if (!config.backend && url.origin === "http://127.0.0.1:3430" &&
          url.pathname === "/" && url.searchParams.has("k")) {
        origin = url.origin;
        return;
      }
      event.preventDefault();
      if (url.protocol === "https:") void shell.openExternal(url.href).catch(() => {});
    });
    win.webContents.on("will-redirect", (event, target) => {
      if (new URL(target).origin !== origin) event.preventDefault();
    });
    win.webContents.setWindowOpenHandler(({ url }) => {
      if (url.startsWith("https://")) void shell.openExternal(url).catch(() => {});
      return { action: "deny" };
    });
    start(win);
  });
  app.on("window-all-closed", () => app.quit());
  app.on("before-quit", () => backend?.kill());
}
