'use strict';
const assert = require('node:assert/strict');
const { EventEmitter } = require('node:events');
const { readFileSync } = require('node:fs');
const { test } = require('node:test');
const { runInNewContext } = require('node:vm');

test('drains only when Claude listens and forwards the URI as argv[1]', async () => {
  const app = new EventEmitter();
  app.whenReady = () => Promise.resolve();
  let calls = 0, tick;
  let release;
  const systemPreferences = {
    callArkTSFunction(name, resultType) {
      assert.equal(name, 'EtsBridge.DrainClaudeLaunchUris');
      assert.equal(resultType, 'string[]');
      ++calls;
      return new Promise(resolve => { release = resolve; });
    },
  };
  const mod = { exports: {} };
  runInNewContext(readFileSync(require.resolve('./claude-launch-bridge.cjs'), 'utf8'), {
    module: mod, require: () => ({ app, systemPreferences }), process,
    setInterval(fn) { tick = fn; return { unref() {} }; },
  });
  mod.exports.startClaudeLaunchBridge();
  await Promise.resolve();
  await tick();
  assert.equal(calls, 0);

  const received = [];
  app.on('second-instance', (_ev, argv, cwd) => received.push({ uri: argv[1], executable: argv[0], cwd }));
  const reading = tick();
  await tick();
  assert.equal(calls, 1);
  release({ type: 'string[]', value: ['https://ignored.invalid/', 'claude://claude.ai/synthetic'] });
  await reading;
  assert.deepEqual(received, [{ uri: 'claude://claude.ai/synthetic', executable: process.execPath, cwd: process.cwd() }]);
});
