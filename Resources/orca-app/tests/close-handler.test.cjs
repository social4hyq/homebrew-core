'use strict';

// The formula injects a windowStageClose handler into the shell's WebAbility.
// Its return value matters: true tells the system not to close the window, false
// lets the system close it right after the hide, which destroys the ability's
// session and kills the app. The ArkTS is only compiled in CI, so this test takes
// the injected lines out of the formula and runs them against stubs.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const formula = fs.readFileSync(path.join(__dirname, '..', '..', '..', 'Formula', 'o', 'orca-app.rb'), 'utf8');

function injectedLines() {
  const match = formula.match(/close_handler = \[\n([\s\S]*?)\n\s*\]\.join\("\\n"\)/);
  assert.ok(match, 'close_handler array not found in the formula');
  return match[1].split('\n').map((line) => {
    const quoted = line.match(/^\s*"(.*)",?$/);
    assert.ok(quoted, `unexpected line in close_handler: ${line}`);
    return quoted[1];
  });
}

// Run the injected block with a fake window stage and return what it registered.
function register({ xcomponentId }) {
  const lines = injectedLines().filter((line) => !line.includes('super.onWindowStageCreate'));
  const hidden = [];
  let registered = null;
  const windowStage = { on: (event, callback) => { registered = { event, callback }; } };
  const stubs = {
    CheckEmptyUtils: { isEmpty: (value) => !value },
    ConfigData: { WINDOW_PREFIX: 'xc_' },
    Inject: { getOrCreate: () => ({ hideWindow: (id) => hidden.push(id) }) },
    AppWindowAdapter: {},
    LogUtil: { error: () => {} },
    TAG: 'test',
  };
  const run = new Function('windowStage', ...Object.keys(stubs), lines.join('\n'));
  run.call({ xcomponentId }, windowStage, ...Object.values(stubs));
  return { registered, hidden };
}

test('registers a windowStageClose handler', () => {
  const { registered } = register({ xcomponentId: 'xc_7' });
  assert.equal(registered.event, 'windowStageClose');
  assert.equal(typeof registered.callback, 'function');
});

test('hides the window and returns true so the system does not close it', () => {
  const { registered, hidden } = register({ xcomponentId: 'xc_7' });
  assert.equal(registered.callback(), true);
  assert.deepEqual(hidden, [7]);
});

test('does not hide and lets the close through while the window has no id yet', () => {
  const { registered, hidden } = register({ xcomponentId: '' });
  assert.equal(registered.callback(), false);
  assert.deepEqual(hidden, []);
});

test('the only return false is the guard for a window without an id', () => {
  const body = injectedLines().join('\n');
  assert.equal((body.match(/return false;/g) || []).length, 1);
  assert.ok(body.indexOf('return false;') < body.indexOf('hideWindow('));
  assert.ok(body.lastIndexOf('return true;') > body.indexOf('hideWindow('));
});
