'use strict';
const assert = require('node:assert/strict');
const { test } = require('node:test');
const path = require('node:path');
const fs = require('node:fs');
const os = require('node:os');
const { configureClaudeConfigDir, usableConfigDir } = require('./claude-ohos-config.cjs');

function tempDir(t, prefix) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), prefix));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  return dir;
}

test('without a host folder, Claude config and workspace trust stay under app-private userData', (t) => {
  const userData = tempDir(t, 'claude-ohos-config-');
  const env = { HOME: '/host/home' };
  const app = { getPath(name) { assert.equal(name, 'userData'); return userData; } };
  assert.deepEqual(configureClaudeConfigDir(app, env), {
    userData, tempDir: path.join(userData, 'tmp'), configDir: userData, shared: false,
  });
  assert.equal(env.CLAUDE_CONFIG_DIR, userData);
  assert.equal(env.TMPDIR, path.join(userData, 'tmp'));
  assert.equal(env.HOME, '/host/home');
  assert.equal(fs.statSync(env.TMPDIR).isDirectory(), true);
});

test('with a usable host folder the main process shares it with the CLI and the terminal', (t) => {
  const userData = tempDir(t, 'claude-ohos-config-');
  const hostDir = path.join(tempDir(t, 'claude-ohos-host-'), '.claude');
  const env = {};
  const result = configureClaudeConfigDir({ getPath: () => userData }, env, { hostConfigDir: hostDir });
  assert.equal(env.CLAUDE_CONFIG_DIR, hostDir);
  assert.equal(result.configDir, hostDir);
  assert.equal(result.shared, true);
  assert.equal(fs.statSync(hostDir).isDirectory(), true, 'created when missing');
  assert.equal(env.TMPDIR, path.join(userData, 'tmp'), 'temporary files stay private');
});

test('a host folder the app cannot use falls back to userData', (t) => {
  const userData = tempDir(t, 'claude-ohos-config-');
  const denied = Object.assign(new Error('denied'), { code: 'EACCES' });
  const noAccess = { mkdirSync() { throw denied; }, accessSync() { throw denied; } };
  const env = {};
  const result = configureClaudeConfigDir({ getPath: () => userData }, env, { hostConfigDir: '/host/home/.claude', fs: noAccess });
  assert.equal(env.CLAUDE_CONFIG_DIR, userData);
  assert.equal(result.shared, false);
});

test('usableConfigDir wants an absolute folder it can read and write', (t) => {
  const dir = tempDir(t, 'claude-ohos-usable-');
  assert.equal(usableConfigDir(dir), true);
  assert.equal(usableConfigDir('relative/.claude'), false);
  assert.equal(usableConfigDir(undefined), false);
  assert.equal(usableConfigDir(''), false);
  const blocker = path.join(dir, 'file');
  fs.writeFileSync(blocker, 'x');
  assert.equal(usableConfigDir(path.join(blocker, 'sub')), false, 'cannot be created under a file');
});

test('fails closed if Electron cannot supply a private config path', () => {
  const env = {};
  assert.throws(() => configureClaudeConfigDir({ getPath: () => '' }, env), /app-private userData/);
  assert.throws(() => configureClaudeConfigDir({ getPath: () => 'relative/path' }, env), /app-private userData/);
  assert.equal(env.CLAUDE_CONFIG_DIR, undefined);
});
