'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const lifecycle = require('../app/lifecycle.cjs');

test('asks only when the shell started the service and it is still up', () => {
  assert.equal(lifecycle.shouldConfirmQuit({ startedService: true, serviceUp: true }), true);
  assert.equal(lifecycle.shouldConfirmQuit({ startedService: true, serviceUp: false }), false);
  assert.equal(lifecycle.shouldConfirmQuit({ startedService: false, serviceUp: true }), false);
  assert.equal(lifecycle.shouldConfirmQuit({ startedService: false, serviceUp: false }), false);
});

test('treats missing flags as "do not ask"', () => {
  assert.equal(lifecycle.shouldConfirmQuit({}), false);
  assert.equal(lifecycle.shouldConfirmQuit({ startedService: true }), false);
});

test('the dialog defaults to cancel and names the way to keep the service', () => {
  const dialog = lifecycle.quitDialog();
  assert.deepEqual(dialog.buttons, ['取消', '仍然退出']);
  assert.equal(dialog.defaultId, 0);
  assert.equal(dialog.cancelId, 0);
  assert.match(dialog.detail, /zcode-app serve/);
});

test('only the second button quits', () => {
  assert.equal(lifecycle.confirmedQuit(1), true);
  assert.equal(lifecycle.confirmedQuit(0), false);
  assert.equal(lifecycle.confirmedQuit(undefined), false);
});

test('the diagnostic line says who started the service and carries nothing else', () => {
  assert.equal(lifecycle.attachLine({ startedService: true }), 'kind=own reason=started-by-shell');
  assert.equal(lifecycle.attachLine({ startedService: false }), 'kind=existing reason=already-serving');
});
