'use strict';

// Minimal Owl-runtime compatibility for the official ChatGPT/Codex desktop
// app on the stock Electron OHOS runtime.
//
// The official build refuses to start on stock Electron unless
// `app.showTaskManager` exists, and it calls a handful of other Owl-only
// methods.  Only the surface the app actually touches is reproduced here.
// Face-value-only features (task manager window, website reporting, browser
// sidebar adoption) stay inert; none of them is required to render the app.

require('./owl-sqlite-shim.cjs');
const crypto = require('node:crypto');
const { app, BrowserWindow, dialog, screen, session } = require('electron');

// ~/Documents is not creatable by the HAP (EPERM on mkdir below it), but the
// app puts its default workspaces there.  Serve a writable directory instead.
try {
  const nodeFs = require('node:fs');
  const nodePath = require('node:path');
  const cfg = JSON.parse(nodeFs.readFileSync(nodePath.join(__dirname, 'chatgpt-host-config.json'), 'utf8'));
  const docs = nodePath.join(cfg.home, '.cache', 'codex-app', 'Documents');
  nodeFs.mkdirSync(docs, { recursive: true });
  const originalGetPath = app.getPath.bind(app);
  app.getPath = (name) => (name === 'documents' ? docs : originalGetPath(name));
} catch (error) {
  console.error('OWL_COMPAT documents override failed: ' + (error && error.message));
}

// Window chrome: the official app only hides the native menu bar on win32/linux
// (autoHideMenuBar), but this runtime reports 'openharmony', so the default
// Electron menu bar shows.  Hide it on every window (accelerators stay active).
app.on('browser-window-created', (_event, win) => {
  try {
    win.setAutoHideMenuBar(true);
    win.setMenuBarVisibility(false);
  } catch (error) {
    console.error('OWL_COMPAT window chrome failed: ' + (error && error.message));
  }
});

const installed = [];
const runtimeFeatures = new Map();

function log(message) {
  try {
    console.log(`OWL_COMPAT ${message}`);
  } catch {
    // logging must never break startup
  }
}

function define(target, name, value) {
  if (target && typeof target[name] !== 'function') {
    target[name] = value;
    installed.push(name);
  }
}

// app.setRuntimeFeatures / app.isRuntimeFeatureEnabled ---------------------
define(app, 'isRuntimeFeatureEnabled', (name) => runtimeFeatures.get(name) === true);
define(app, 'setRuntimeFeatures', (state) => {
  if (state === null || typeof state !== 'object') {
    throw new TypeError('app.setRuntimeFeatures requires a feature state object');
  }
  for (const [name, value] of Object.entries(state)) {
    if (typeof value === 'boolean') runtimeFeatures.set(name, value);
  }
});

// Misc Owl-only app hooks ------------------------------------------------
// Debug Chrome pages and native menu tracking are Owl-shell plumbing with no
// stock-Electron equivalent; the app only uses them for optional features.
define(app, 'setDebugChromePagesEnabled', () => {});
define(app, 'requireWebRequestForNetworking', () => {});
define(app, 'beginNativeMenuTracking', () => {});
define(app, 'endNativeMenuTracking', () => {});

// app.showTaskManager -----------------------------------------------------
// The real Owl build opens Chromium's task manager. Stock Electron has no such
// window, so show the equivalent process list in a dialog instead of leaving a
// dead Help -> Task Manager menu item.
define(app, 'showTaskManager', () => {
  if (!app.isReady()) return;
  let detail = 'No processes';
  try {
    detail = app.getAppMetrics().map((metric) => {
      const memory = Math.round((metric.memory?.workingSetSize ?? 0) / 1024);
      const cpu = (metric.cpu?.percentCPUUsage ?? 0).toFixed(1);
      const name = metric.name ? ` ${metric.name}` : '';
      return `${metric.type}${name}  pid=${metric.pid}  ${memory} MB  cpu=${cpu}%`;
    }).join('\n') || detail;
  } catch (error) {
    detail = `Task list unavailable: ${error.message}`;
  }
  dialog.showMessageBox({
    type: 'info',
    title: 'Task Manager',
    message: 'ChatGPT processes',
    detail,
    buttons: ['Close'],
  });
});

// Session-level Owl APIs -----------------------------------------------
// setWebsiteReportingEnabled only toggles a reporting preference. There is no
// equivalent in stock Electron and no behavioural dependency on it.
function patchSession(target) {
  if (!target) return;
  define(target, 'setWebsiteReportingEnabled', () => {});
  // Owl-only in-app browser hook; stock Electron has no permission prompt UI.
  define(target, 'setPermissionPromptHandler', () => {});
}

app.whenReady().then(() => {
  patchSession(session.defaultSession);
  define(screen, 'isCursorScreenPointSupported', () => false);
});
app.on('session-created', (target) => patchSession(target));

// BrowserWindow / screen capability probes ------------------------------
// Owl reports optional native window capabilities through static probes.
// Stock Electron OHOS has no input-shape or system-backdrop support, and the
// app treats false as "use the portable path".
for (const name of ['isInputShapeSupported', 'isSystemBackdropSupported', 'isAlwaysOnTopSupported']) {
  define(BrowserWindow, name, () => false);
}

// WebContents-level Owl APIs -------------------------------------------
// Browser-sidebar webview adoption and the agent-active marker are only used
// by the in-app browser. Stub them so opening a browser tab cannot crash the
// main process; the lease just needs to be a non-empty opaque string.
function patchContents(contents) {
  if (!contents) return;
  define(contents, 'setAgentActive', () => {});
  define(contents, '_createWebViewAdoptionLease', () => crypto.randomUUID());
  define(contents, 'attachBrowserUseNetworkPolicy', () => {});
  define(contents, 'setPageCapturePaintLeaseEnabled', () => {});
  define(contents, 'setDevToolsStyle', () => {});
}

app.on('web-contents-created', (_event, contents) => patchContents(contents));

log(`installed=${installed.join(',')}`);
