'use strict';

// Redirect spawns of the bundled linux/glibc `codex` CLI to the host
// Homebrew CLI.  The bootstrap only patches the main process; the app-server
// host runs in a utilityProcess, so this file is also loaded via --require.
const path = require('node:path');
const fs = require('node:fs');
const childProcess = require('node:child_process');

// Diagnostics go to the app log; a file copy is written only when the user
// creates ~/.cache/codex-app/owl-debug.log (the file's existence is the switch).
let debugLog = null;
function log(msg) {
  try { console.log(msg); } catch (_) {}
  try {
    if (debugLog === null) {
      const cfg = JSON.parse(fs.readFileSync(path.join(__dirname, 'chatgpt-host-config.json'), 'utf8'));
      const file = path.join(cfg.home, '.cache', 'codex-app', 'owl-debug.log');
      debugLog = fs.existsSync(file) ? file : '';
    }
    if (debugLog) {
      fs.appendFileSync(debugLog, new Date().toISOString() + ' [' + (process.type || 'node') + ':' +
        process.pid + '] ' + msg + '\n');
    }
  } catch (_) {
    debugLog = '';
  }
}

if (!childProcess.spawn.__owlHostShim) {
  log('OWL_HOST shim loading __dirname=' + __dirname);
  let cfg = null;
  try {
    cfg = JSON.parse(fs.readFileSync(path.join(__dirname, 'chatgpt-host-config.json'), 'utf8'));
  } catch (_) {}
  if (cfg && path.isAbsolute(cfg.home) && path.isAbsolute(cfg.codexCli) && path.isAbsolute(cfg.codexHome)) {
    const hostHome = cfg.home;
    const codexCli = cfg.codexCli;
    const hostPath = typeof cfg.path === 'string' && cfg.path.length
      ? cfg.path
      : '/system/bin:/system/xbin:/usr/bin:/bin:/vendor/bin';
    process.env.CODEX_CLI_PATH = codexCli;
    for (const name of ['spawn', 'spawnSync', 'execFile', 'execFileSync']) {
      const original = childProcess[name];
      const wrapped = function (command, ...args) {
        const base = typeof command === 'string' ? path.basename(command) : '';
        if (command !== codexCli && !/^codex(?:\.exe)?$/i.test(base)) {
          return original.call(this, command, ...args);
        }
        const forwarded = args.slice();
        let oi = forwarded.findIndex((v) => v && typeof v === 'object' && !Array.isArray(v));
        if (oi < 0) {
          const ci = forwarded.findIndex((v) => typeof v === 'function');
          if (ci === 0) { forwarded.unshift({}); oi = 0; }
          else if (ci > 0) { forwarded.splice(ci, 0, {}); oi = ci; }
          else if (forwarded.length && Array.isArray(forwarded[0])) { forwarded.push({}); oi = forwarded.length - 1; }
          else { forwarded.unshift([]); forwarded.push({}); oi = forwarded.length - 1; }
        }
        const options = forwarded[oi] || {};
        const env = { ...process.env, ...(options.env || {}) };
        env.HOME = hostHome;
        env.CODEX_HOME = cfg.codexHome;
        env.CODEX_CLI_PATH = codexCli;
        env.PATH = hostPath;
        // Optional host-side environment (e.g. proxy settings): HAP processes do
        // not inherit the user's shell environment.
        try {
          const extra = JSON.parse(fs.readFileSync(path.join(hostHome, '.config/codex-app/env.json'), 'utf8'));
          for (const [k, v] of Object.entries(extra)) if (typeof v === 'string') env[k] = v;
        } catch (_) {}
        const cwd = typeof options.cwd === 'string' && path.isAbsolute(options.cwd) ? options.cwd : hostHome;
        forwarded[oi] = { ...options, cwd, env };
        let result;
        try {
          result = original.call(this, codexCli, ...forwarded);
        } catch (e) {
          log('OWL_HOST ' + name + ' threw ' + (e && e.code) + ' ' + (e && e.message));
          throw e;
        }
        if (name === 'spawn' && result && typeof result.once === 'function') {
          log('OWL_HOST spawn redirected from=' + command + ' pid=' + result.pid + ' proc=' + (process.type || 'node'));
          result.once('error', (e) => log('OWL_HOST child error ' + (e && e.code) + ' ' + (e && e.message)));
          result.once('exit', (c, sg) => log('OWL_HOST child exit code=' + c + ' signal=' + sg));
        }
        return result;
      };
      wrapped.__owlHostShim = true;
      childProcess[name] = wrapped;
    }
    log('OWL_HOST shim active pid=' + process.pid + ' type=' + (process.type || 'node'));
  }
}


if (process.type === 'utility') {
  try {
    const hostCfg = JSON.parse(fs.readFileSync(path.join(__dirname, 'chatgpt-host-config.json'), 'utf8'));
    const extra = JSON.parse(fs.readFileSync(path.join(hostCfg.home, '.config/codex-app/env.json'), 'utf8'));
    let applied = 0;
    for (const [k, v] of Object.entries(extra)) {
      if (/proxy$/i.test(k) && typeof v === 'string') { process.env[k] = v; applied++; }
    }
    if (applied > 0) {
      process.env.NODE_USE_ENV_PROXY = '1';
      if (typeof extra.NO_PROXY === 'string') process.env.NO_PROXY = extra.NO_PROXY;
      log('OWL_PROXY applied vars=' + applied + ' NODE_USE_ENV_PROXY=1');
    }
  } catch (_) {}
}

module.exports = { log };

// The terminal backend needs the host Node + node-pty; the main process only.
if (process.type === 'browser') {
  try { require('./owl-pty-shim.cjs'); } catch (e) { log('OWL_PTY shim failed: ' + (e && e.message)); }
}
