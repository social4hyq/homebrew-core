'use strict';

// Keep the vendor Electron main process and its platform checks intact.
const path = require('node:path');
const fs = require('node:fs');
const { app } = require('electron');
const hostConfigPath = path.join(__dirname, 'chatgpt-host-config.json');

// The OHOS Electron shell exposes appData as an unsupported path. The
// official main process reads it during startup, so map it to the app's
// private userData directory before loading the vendor entry point.
const privateDataBase = app.getPath('userData');
if (typeof privateDataBase !== 'string' || !path.isAbsolute(privateDataBase)) {
  throw new Error('Electron did not provide a private userData path');
}
fs.mkdirSync(privateDataBase, { recursive: true, mode: 0o700 });
app.setPath('appData', privateDataBase);

function absolute(value, label) {
  if (typeof value !== 'string' || !path.isAbsolute(value)) {
    throw new Error(`invalid ChatGPT host config: ${label} must be an absolute path`);
  }
  return value;
}

const hostConfig = JSON.parse(fs.readFileSync(hostConfigPath, 'utf8'));
const hostHome = absolute(hostConfig.home, 'home');
const codexCli = absolute(hostConfig.codexCli, 'codexCli');
const codeHome = absolute(hostConfig.codexHome, 'codexHome');
const hostPath = typeof hostConfig.path === 'string' && hostConfig.path.length
  ? hostConfig.path
  : '/system/bin:/system/xbin:/usr/bin:/bin:/vendor/bin';

// ChatGPT's Linux app explicitly supports CODEX_CLI_PATH as the host CLI
// override. Set it before loading the original entry point; do not alter the
// Electron runtime's platform value or the vendor app's permission checks.
process.env.CODEX_CLI_PATH = codexCli;

const childProcess = require('node:child_process');
for (const name of ['spawn', 'spawnSync', 'execFile', 'execFileSync']) {
  const original = childProcess[name];
  childProcess[name] = function(command, ...args) {
    const base = typeof command === 'string' ? path.basename(command) : '';
    if (command !== codexCli && !/^codex(?:\.exe)?$/i.test(base)) {
      return original.call(this, command, ...args);
    }

    const forwarded = args.slice();
    let optionsIndex = forwarded.findIndex(value => value && typeof value === 'object' && !Array.isArray(value));
    if (optionsIndex < 0) {
      const callbackIndex = forwarded.findIndex(value => typeof value === 'function');
      if (callbackIndex === 0) {
        forwarded.unshift({});
        optionsIndex = 0;
      } else if (callbackIndex > 0) {
        forwarded.splice(callbackIndex, 0, {});
        optionsIndex = callbackIndex;
      } else if (forwarded.length && Array.isArray(forwarded[0])) {
        forwarded.push({});
        optionsIndex = forwarded.length - 1;
      } else {
        forwarded.unshift([]);
        forwarded.push({});
        optionsIndex = forwarded.length - 1;
      }
    }
    const options = forwarded[optionsIndex] || {};
    const env = { ...process.env, ...(options.env || {}) };
    env.HOME = hostHome;
    env.CODEX_HOME = codeHome;
    env.CODEX_CLI_PATH = codexCli;
    env.PATH = hostPath;
    const cwd = typeof options.cwd === 'string' && path.isAbsolute(options.cwd)
      ? options.cwd
      : hostHome;
    forwarded[optionsIndex] = { ...options, cwd, env };
    return original.call(this, codexCli, ...forwarded);
  };
}

const vendor = path.join(__dirname, 'vendor.asar');
app.setName('ChatGPT');
app.setAppPath(vendor);

const vendorPackage = require(path.join(vendor, 'package.json'));
if (vendorPackage.version !== '26.1117.31558' ||
    vendorPackage.main !== '.vite/build/early-bootstrap.js') {
  throw new Error('unexpected official ChatGPT application entry point');
}
require(path.join(vendor, vendorPackage.main));
