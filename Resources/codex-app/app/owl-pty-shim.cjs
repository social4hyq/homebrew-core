'use strict';

// Replacement for the bundled `node-pty` (linux/glibc, cannot load on OHOS).
// Each terminal is backed by a host Node helper (owl-pty-host.cjs) that runs
// the host's OHOS build of node-pty; this module only mimics the small part of
// the node-pty API the app uses: spawn(file,args,opts) -> {pid,onData,onExit,
// write,resize,kill}.  Main process only.

const Module = require('node:module');
const path = require('node:path');
const fs = require('node:fs');
const childProcess = require('node:child_process');
const { EventEmitter } = require('node:events');

const { log } = require('./owl-host-shim.cjs');

let cfg = {};
try {
  cfg = JSON.parse(fs.readFileSync(path.join(__dirname, 'chatgpt-host-config.json'), 'utf8'));
} catch (_) {}
const hostHome = typeof cfg.home === 'string' ? cfg.home : null;
const hostPath = typeof cfg.path === 'string' && cfg.path.length
  ? cfg.path
  : '/system/bin:/system/xbin:/usr/bin:/bin:/vendor/bin';

function firstExisting(candidates) {
  for (const c of candidates) {
    if (typeof c === 'string' && path.isAbsolute(c)) {
      try { fs.accessSync(c, fs.constants.X_OK); return c; } catch (_) {}
    }
  }
  return null;
}

// Host Node and its node-pty are provided by the installer through the host
// config (chatgpt-host-config.json: nodeCli, nodePtyDir).
const hostNode = firstExisting([cfg.nodeCli, hostHome && path.join(hostHome, '.harmonybrew/opt/node/bin/node')]);
const nodePtyDir = typeof cfg.nodePtyDir === 'string' && path.isAbsolute(cfg.nodePtyDir) ? cfg.nodePtyDir : null;
const helper = path.join(__dirname, 'owl-pty-host.cjs');

function resolveShell(file) {
  // Prefer the host's bash, then zsh; fall back to what the app asked for and
  // finally /bin/sh (the app's default here, which is a bare busybox-style sh).
  const found = firstExisting([
    hostHome && path.join(hostHome, '.harmonybrew/bin/bash'),
    hostHome && path.join(hostHome, '.harmonybrew/bin/zsh'),
    file,
    '/bin/sh',
  ]);
  return found || file;
}

// Proxy variables from the optional host env file (see owl-host-shim.cjs); HAP
// processes do not inherit the user's shell environment.
function hostProxyEnv() {
  try {
    const extra = JSON.parse(fs.readFileSync(path.join(hostHome, '.config/codex-app/env.json'), 'utf8'));
    const out = {};
    for (const [k, v] of Object.entries(extra)) if (/proxy$/i.test(k) && typeof v === 'string') out[k] = v;
    return out;
  } catch (_) {
    return {};
  }
}

class OwlPty {
  constructor(file, args, options) {
    this._events = new EventEmitter();
    this.pid = undefined;
    this.cols = options.cols || 80;
    this.rows = options.rows || 24;
    this._exited = false;
    this._buffer = '';

    if (!hostNode) throw new Error('host Node not found for terminal helper');
    if (!nodePtyDir) throw new Error('node-pty directory missing from the host config');
    const shell = resolveShell(file);
    const env = { ...(options.env || process.env) };
    env.HOME = hostHome || env.HOME;
    env.PATH = hostPath;
    env.SHELL = shell;
    Object.assign(env, hostProxyEnv());
    env.TERM = env.TERM || 'xterm-256color';
    // Nothing of the HAP's Electron/Node runtime should leak into the shell.
    delete env.NODE_OPTIONS;
    delete env.NODE_USE_ENV_PROXY;
    let cwd = typeof options.cwd === 'string' && path.isAbsolute(options.cwd) ? options.cwd : hostHome;
    try { if (!fs.statSync(cwd).isDirectory()) cwd = hostHome; } catch (_) { cwd = hostHome; }

    this._child = childProcess.spawn(hostNode, [helper], {
      stdio: ['pipe', 'pipe', 'pipe'],
      cwd: hostHome || undefined,
      env: { HOME: hostHome, PATH: hostPath, OWL_NODE_PTY_DIR: nodePtyDir },
    });
    log('OWL_PTY helper pid=' + this._child.pid + ' shell=' + shell + ' cwd=' + cwd + ' size=' + this.cols + 'x' + this.rows);
    this._child.stdout.setEncoding('utf8');
    this._child.stdout.on('data', (chunk) => this._onStdout(chunk));
    this._child.stderr.on('data', (chunk) => log('OWL_PTY helper stderr: ' + String(chunk).slice(0, 300)));
    this._child.on('error', (error) => { log('OWL_PTY helper error ' + error.message); this._finish(1, null); });
    this._child.on('close', (code) => this._finish(code == null ? 1 : code, null));
    this._send({ t: 'spawn', file: shell, args, cwd, env, cols: this.cols, rows: this.rows });
  }

  _send(message) {
    if (this._exited || !this._child.stdin.writable) return;
    this._child.stdin.write(JSON.stringify(message) + '\n');
  }

  _onStdout(chunk) {
    this._buffer += chunk;
    let index;
    while ((index = this._buffer.indexOf('\n')) >= 0) {
      const line = this._buffer.slice(0, index);
      this._buffer = this._buffer.slice(index + 1);
      if (!line) continue;
      let msg;
      try { msg = JSON.parse(line); } catch (_) { continue; }
      if (msg.t === 'data') this._events.emit('data', msg.d);
      else if (msg.t === 'ready') { this.pid = msg.pid; log('OWL_PTY ready pid=' + msg.pid); }
      else if (msg.t === 'exit') this._finish(msg.code, msg.signal);
      else if (msg.t === 'error') log('OWL_PTY error: ' + msg.m);
    }
  }

  _finish(exitCode, signal) {
    if (this._exited) return;
    this._exited = true;
    log('OWL_PTY exit code=' + exitCode + ' signal=' + signal);
    this._events.emit('exit', { exitCode, signal });
    try { this._child.stdin.end(); } catch (_) {}
  }

  onData(listener) {
    this._events.on('data', listener);
    return { dispose: () => this._events.off('data', listener) };
  }

  onExit(listener) {
    this._events.on('exit', listener);
    return { dispose: () => this._events.off('exit', listener) };
  }

  write(data) { this._send({ t: 'write', d: String(data) }); }

  resize(cols, rows) {
    this.cols = cols;
    this.rows = rows;
    this._send({ t: 'resize', c: cols, r: rows });
  }

  kill(signal) { this._send({ t: 'kill', s: signal }); }
  pause() {}
  resume() {}
  clear() {}
}

const ptyModule = {
  spawn: (file, args, options) => new OwlPty(file, args || [], options || {}),
};

if (!Module._load.__owlPty) {
  const originalLoad = Module._load;
  const wrapped = function (request, parent, isMain) {
    if (request === 'node-pty') return ptyModule;
    return originalLoad.apply(this, arguments);
  };
  wrapped.__owlPty = true;
  Module._load = wrapped;
  log('OWL_PTY shim active hostNode=' + hostNode + ' nodePtyDir=' + nodePtyDir);
}

module.exports = ptyModule;
