'use strict';
// Pure-JS replacement for the `starship` module that Postman's own Electron
// fork exposes as a built-in (resolved through process._linkedBinding). The
// Electron-OHOS shell has no such built-in, so main.js fails with
// "Cannot find module 'starship'". Only the two APIs Postman actually uses are
// implemented here.
const fs = require('node:fs');
const path = require('node:path');

exports.operatingSystemArchitecture = process.arch.replace('ia32', 'x86');

let optionsCache;
function loadOptions() {
  if (optionsCache !== undefined) return optionsCache;
  optionsCache = {};
  try {
    const profile = JSON.parse(
      fs.readFileSync(path.join(process.resourcesPath, 'profile.json'), 'utf8'),
    );
    if (profile && profile.installationOptions) {
      optionsCache = profile.installationOptions;
    }
  } catch (_) {
    // No profile.json in the HAP: Postman's default (no options) behavior.
  }
  return optionsCache;
}

exports.installationOptions = {
  async get(id) {
    if (!/^[A-Z]+(_[A-Z]+)*$/.test(id)) {
      throw new Error('The id must be a sequence of upper case English letters that could be separated by single underscores.');
    }
    const options = loadOptions();
    if (Object.keys(options).length === 0) return null;
    const entry = options[id];
    if (!entry) throw new Error('installationOptions~get : The id could not be found in the installation options.');
    const { type, default: fallback } = entry;
    if (!['boolean', 'integer', 'string'].includes(type)) {
      throw new Error('The type must either be boolean, integer or string.');
    }
    // On OHOS there is no snap registry; return the packaged default.
    return fallback;
  },
};
