'use strict';
const assert = require('node:assert/strict');
const { test } = require('node:test');
const path = require('node:path');
const fs = require('node:fs');
const os = require('node:os');
const { configureClaudeConfigDir } = require('./claude-ohos-config.cjs');

test('stores Claude config and workspace trust under app-private userData', () => {
  const userData = fs.mkdtempSync(path.join(os.tmpdir(), 'claude-ohos-config-'));
  try {
    const env = { HOME: '/host/home' };
    const app = { getPath(name) { assert.equal(name, 'userData'); return userData; } };
    assert.deepEqual(configureClaudeConfigDir(app, env), {
      userData, tempDir: path.join(userData, 'tmp'),
    });
    assert.equal(env.CLAUDE_CONFIG_DIR, userData);
    assert.equal(env.TMPDIR, path.join(userData, 'tmp'));
    assert.equal(env.HOME, '/host/home');
    assert.equal(fs.statSync(env.TMPDIR).isDirectory(), true);
  } finally {
    fs.rmSync(userData, { recursive: true, force: true });
  }
});

test('fails closed if Electron cannot supply a private config path', () => {
  const env = {};
  assert.throws(() => configureClaudeConfigDir({ getPath: () => '' }, env), /app-private userData/);
  assert.throws(() => configureClaudeConfigDir({ getPath: () => 'relative/path' }, env), /app-private userData/);
  assert.equal(env.CLAUDE_CONFIG_DIR, undefined);
});
