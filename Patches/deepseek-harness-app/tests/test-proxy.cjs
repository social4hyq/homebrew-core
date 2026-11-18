'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { normalizeProxySettings, toElectronProxyConfig } = require(process.env.DSH_APP_PROXY_HELPER || '../app/proxy.cjs');

test('supports direct and system proxy modes', () => {
  assert.deepEqual(toElectronProxyConfig({ mode: 'direct' }), { mode: 'direct' });
  assert.deepEqual(toElectronProxyConfig({ mode: 'system' }), { mode: 'system' });
});

test('normalizes manual HTTP and SOCKS proxy endpoints', () => {
  assert.deepEqual(normalizeProxySettings({ mode: 'manual', url: 'http://localhost:8080' }),
    { mode: 'manual', url: 'http://localhost:8080' });
  assert.deepEqual(toElectronProxyConfig({ mode: 'manual', url: 'socks5://127.0.0.1:1080' }),
    { proxyRules: 'socks5://127.0.0.1:1080' });
});

test('rejects malformed, unsupported, or portless manual proxy values', () => {
  for (const value of [
    { mode: 'other' },
    { mode: 'manual', url: 'not a URL' },
    { mode: 'manual', url: 'ftp://proxy.example:21' },
    { mode: 'manual', url: 'http://proxy.example' },
  ]) assert.throws(() => normalizeProxySettings(value));
});
