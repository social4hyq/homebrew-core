'use strict';

const assert = require('node:assert/strict');
const path = require('node:path');
const test = require('node:test');

const share = require('../app/owl-share.cjs');

const home = '/storage/Users/currentUser';
const endpoint = share.endpointFile(home);
const bridge = '/data/app/owl-codex-bridge.cjs';
const node = '/storage/Users/currentUser/.harmonybrew/opt/node/bin/node';
const codex = '/storage/Users/currentUser/.harmonybrew/opt/codex/bin/codex';
const desktopArgs = ['-c', 'features.code_mode_host=true', 'app-server', '--analytics-default-enabled'];

function fakeFs(files) {
  return {
    readFileSync(file) {
      if (!(file in files)) throw Object.assign(new Error('ENOENT'), { code: 'ENOENT' });
      return files[file];
    },
  };
}

const goodEndpoint = JSON.stringify({ version: 1, port: 14288, tokenFile: home + '/.config/codex-app/ws-token' });

test('endpointFile sits under the host home', () => {
  assert.equal(endpoint, path.join(home, '.config', 'codex-app', 'server.json'));
});

test('isDesktopAppServerArgs accepts what the desktop passes', () => {
  assert.equal(share.isDesktopAppServerArgs(desktopArgs), true);
  assert.equal(share.isDesktopAppServerArgs(['app-server']), true);
  assert.equal(share.isDesktopAppServerArgs(
    ['-c', 'features.code_mode_host=true', 'app-server', '-c', 'openai_base_url="http://x"', '--analytics-default-enabled']), true);
});

test('isDesktopAppServerArgs rejects every other codex invocation', () => {
  for (const args of [
    [], ['--version'], ['exec', 'hi'], ['app-server', 'daemon', 'version'], ['app-server', 'proxy'],
    ['app-server', '--listen', 'unix://'], ['app-server', '--stdio'], ['app-server', 'generate-ts'],
    ['app-server', 'app-server'], ['-c'], ['-c', 'a=b'], ['--analytics-default-enabled'],
    ['--analytics-default-enabled', 'app-server'],
  ]) {
    assert.equal(share.isDesktopAppServerArgs(args), false, JSON.stringify(args));
  }
  assert.equal(share.isDesktopAppServerArgs(null), false);
  assert.equal(share.isDesktopAppServerArgs('app-server'), false);
  assert.equal(share.isDesktopAppServerArgs(['app-server', 7]), false);
});

test('readEndpoint reads a valid file and refuses anything else', () => {
  assert.deepEqual(share.readEndpoint(endpoint, fakeFs({ [endpoint]: goodEndpoint })),
    { port: 14288, tokenFile: home + '/.config/codex-app/ws-token' });
  assert.equal(share.readEndpoint(endpoint, fakeFs({})), null);
  for (const text of [
    'not json', '{}', JSON.stringify({ version: 2, port: 1, tokenFile: '/t' }),
    JSON.stringify({ version: 1, port: 0, tokenFile: '/t' }), JSON.stringify({ version: 1, port: 70000, tokenFile: '/t' }),
    JSON.stringify({ version: 1, port: '14288', tokenFile: '/t' }), JSON.stringify({ version: 1, port: 14288, tokenFile: 'relative' }),
    JSON.stringify({ version: 1, port: 14288 }),
  ]) {
    assert.equal(share.readEndpoint(endpoint, fakeFs({ [endpoint]: text })), null, text);
  }
});

test('planRedirect runs the app-server spawn through the bridge when a server is registered', () => {
  const plan = share.planRedirect({
    name: 'spawn', args: desktopArgs, hostNode: node, bridge, endpoint, codexCli: codex, fs: fakeFs({ [endpoint]: goodEndpoint }),
  });
  assert.deepEqual(plan, {
    command: node,
    args: [bridge, '--endpoint', endpoint, '--codex', codex, '--', ...desktopArgs],
  });
});

test('planRedirect keeps the original spawn in every other case', () => {
  const base = { name: 'spawn', args: desktopArgs, hostNode: node, bridge, endpoint, codexCli: codex, fs: fakeFs({ [endpoint]: goodEndpoint }) };
  assert.equal(share.planRedirect({ ...base, fs: fakeFs({}) }), null, 'no server registered');
  assert.equal(share.planRedirect({ ...base, fs: fakeFs({ [endpoint]: 'junk' }) }), null, 'unusable endpoint file');
  assert.equal(share.planRedirect({ ...base, hostNode: null }), null, 'no host node');
  assert.equal(share.planRedirect({ ...base, name: 'execFile' }), null, 'not a spawn');
  assert.equal(share.planRedirect({ ...base, args: ['--version'] }), null, 'not an app-server');
  assert.equal(share.planRedirect({ ...base, args: ['app-server', 'daemon', 'start'] }), null, 'a daemon command');
});
