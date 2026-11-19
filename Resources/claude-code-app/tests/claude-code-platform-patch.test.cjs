'use strict';
const assert = require('node:assert/strict');
const { test } = require('node:test');
const { patchCodeManagerSource } = require('./claude-code-platform-patch.cjs');

const originalPlatform = 'getHostPlatform(){let e=process.arch;if(process.platform==="darwin")return e==="arm64"?"darwin-arm64":"darwin-x64";if(process.platform==="win32")return e==="arm64"?"win32-arm64":"win32-x64";if(process.platform==="linux")return e==="arm64"?"linux-arm64":"linux-x64";throw Error(`Unsupported platform: ${process.platform}-${e}`)}';
const patchedPlatform = originalPlatform.replace('if(process.platform==="linux")', 'if(process.platform==="linux"||process.platform==="openharmony")');
const originalWindow = 'titleBarStyle:"hidden",titleBarOverlay:!0,trafficLightPosition:yRa(),show:i&&!0';
const patchedWindow = 'titleBarStyle:"default",titleBarOverlay:!1,frame:!0,trafficLightPosition:yRa(),show:i&&!0';

test('maps only the Code manager host target to its Linux ARM64 compatibility target', () => {
  const source = `class Manager{constructor(){this.localBinaryPath=null,this.localBinaryInitPromise=null,this.skipPreseedThisProcess=!1}${originalPlatform}}function mainWindow(){return{${originalWindow}}}`;
  const patched = patchCodeManagerSource(source);
  assert.ok(patched.includes(patchedPlatform));
  assert.ok(patched.includes('this.localBinaryInitPromise=process.env.CLAUDE_CODE_LOCAL_BINARY?this.initLocalBinary(process.env.CLAUDE_CODE_LOCAL_BINARY):null,'));
  assert.ok(patched.includes(patchedWindow));
  assert.ok(!patched.includes('process.platform="linux"'));
  assert.equal(patchCodeManagerSource(patched), patched);
});

test('fails closed on an unknown vendor chunk layout', () => {
  assert.throws(() => patchCodeManagerSource('class Manager {}'), /anchor mismatch/);
});
