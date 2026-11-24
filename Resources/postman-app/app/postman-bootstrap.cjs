'use strict';
// Electron-OHOS entry for the Postman shell. Runs under the weak sandbox: the
// host home is visible and host binaries are executable, so we only need to
// hand the host PATH to child processes and load the vendor main module.

const path = require('node:path');
const fs = require('node:fs');
const { app } = require('electron');

const vendor = path.join(__dirname, 'vendor');

// native addons trimmed at assemble time are loaded by Postman inside
// try/catch; nothing extra is needed here, but make dlopen failures explicit
// in logs rather than silent so a feature gap is diagnosable.
function installDlopenDiag() {
  const dlopen = process.dlopen;
  if (typeof dlopen !== 'function') return;
  process.dlopen = function (module, filename, flags) {
    try {
      return dlopen.call(this, module, filename, flags);
    } catch (error) {
      console.error('postman: native addon unavailable: ' + filename + ' - ' + error.message);
      throw error;
    }
  };
}

function hostConfig() {
  const configPath = path.join(__dirname, 'postman-host-config.json');
  try {
    return JSON.parse(fs.readFileSync(configPath, 'utf8'));
  } catch (_) {
    return {};
  }
}

const config = hostConfig();
if (typeof config.path === 'string' && config.path) {
  process.env.PATH = config.path;
}
if (typeof config.home === 'string' && config.home) {
  process.env.HOME = config.home;
}

installDlopenDiag();

const vendorPackage = require(path.join(vendor, 'package.json'));
if (vendorPackage.version !== require(path.join(__dirname, 'package.json')).version) {
  throw new Error('postman: vendor version does not match shell version');
}
app.setAppPath(vendor);
require(path.join(vendor, vendorPackage.main || 'main.js'));
