'use strict';
// Electron-OHOS entry for the Bruno shell. Bruno is local-first and needs no
// account. Two adaptations for the OHOS runtime:
//  1. stub @lydell/node-pty (its native addon cannot be dlopen'd from the
//     HAP's read-only bundle; only the in-app terminal is affected), and
//  2. hand the host PATH/HOME to any child processes Bruno spawns.

const fs = require('node:fs');
const path = require('node:path');
const Module = require('node:module');
const { app } = require('electron');

const vendor = path.join(__dirname, 'vendor.asar');

// node-pty's glibc addon cannot load under the app sandbox. Replace the module
// with a minimal stub so Bruno's main process initialises; terminal features
// degrade gracefully while the API client works fully.
const originalLoad = Module._load;
Module._load = function (request, parent, isMain) {
  if (request === '@lydell/node-pty') {
    const unavailable = () => { throw new Error('bruno: terminal unavailable on OpenHarmony'); };
    return { spawn: unavailable, fork: unavailable, createTerminal: unavailable,
             open: unavailable, Terminal: function () { unavailable(); } };
  }
  return originalLoad.call(this, request, parent, isMain);
};

function hostConfig() {
  try {
    return JSON.parse(fs.readFileSync(path.join(__dirname, 'host-config.json'), 'utf8'));
  } catch (_) {
    return {};
  }
}
const config = hostConfig();
if (typeof config.path === 'string' && config.path) process.env.PATH = config.path;
if (typeof config.home === 'string' && config.home) process.env.HOME = config.home;

const vendorPackage = require(path.join(vendor, 'package.json'));
if (vendorPackage.version !== require(path.join(__dirname, 'package.json')).version) {
  throw new Error('bruno: vendor version does not match shell version');
}
app.setAppPath(vendor);
require(path.join(vendor, vendorPackage.main || 'src/index.js'));
