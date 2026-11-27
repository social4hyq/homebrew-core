'use strict';

// stage-ohos-shell.sh injects a windowStageClose handler into the shell's
// WebAbility.ets. Its return value matters: true tells the system not to close the
// window (it was hidden to the tray), false lets the system close it right after the
// hide, which destroys the ability's session and ends the process. The ArkTS is only
// compiled in CI, so this test runs the staging script on a small template, then runs
// the injected lines against stubs.
const assert = require('node:assert/strict');
const childProcess = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');

const stage = path.join(__dirname, '..', 'scripts', 'stage-ohos-shell.sh');
const WEB_ABILITY = 'web_engine/src/main/ets/ability/WebAbility.ets';
const ORIGINAL = [
  'export default class WebAbility extends UIAbility {',
  '  onWindowStageCreate(windowStage: window.WindowStage): void {',
  '    super.onWindowStageCreate(windowStage);',
  '    this.afterCreate();',
  '  }',
  '}',
  '',
].join('\n');

// The parts of the electron-ohos template the staging script touches.
function template(root) {
  const write = (file, text) => {
    fs.mkdirSync(path.dirname(path.join(root, file)), { recursive: true });
    fs.writeFileSync(path.join(root, file), text);
  };
  write('AppScope/app.json5', '{"app":{"bundleName":"com.huawei.ohos_electron","vendor": "example","versionCode": 1000001,"versionName": "1.0.1"}}');
  write('electron/libs/arm64-v8a/libelectron.so', 'x');
  write('build-profile.json5', '{\n  "signingConfig": "default",\n}');
  write('electron/src/main/module.json5', '{"scheme": "electron"}');
  write('web_engine/src/main/module.json5', '{\n  "requestPermissions": [\n    { "name": "x" }\n    ]\n}');
  write(WEB_ABILITY, ORIGINAL);
  fs.mkdirSync(path.join(root, 'AppScope/resources/base/media'), { recursive: true });
}

function staged(t) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'codex-stage-'));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  template(path.join(dir, 'template'));
  const result = childProcess.spawnSync('bash', [stage, path.join(dir, 'template'), path.join(dir, 'out'), '26.1117.41037'], { encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr);
  return fs.readFileSync(path.join(dir, 'out', WEB_ABILITY), 'utf8');
}

test('the staging script injects the handler right after super.onWindowStageCreate', (t) => {
  const text = staged(t);
  assert.match(text, /super\.onWindowStageCreate\(windowStage\);\n    try \{\n      windowStage\.on\('windowStageClose'/);
  assert.equal((text.match(/super\.onWindowStageCreate\(windowStage\);/g) || []).length, 1, 'the original line is replaced, not duplicated');
  assert.match(text, /this\.afterCreate\(\);/, 'the rest of the method is kept');
});

function injectedLines(text) {
  const start = text.indexOf('    try {\n      windowStage.on(');
  const end = text.indexOf('    this.afterCreate();');
  return text.slice(start, end).split('\n');
}

// Run the injected block with a fake window stage and return what it registered.
function register(text, { xcomponentId }) {
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
  const run = new Function('windowStage', ...Object.keys(stubs), injectedLines(text).join('\n'));
  run.call({ xcomponentId }, windowStage, ...Object.values(stubs));
  return { registered, hidden };
}

test('registers a windowStageClose handler', (t) => {
  const { registered } = register(staged(t), { xcomponentId: 'xc_7' });
  assert.equal(registered.event, 'windowStageClose');
  assert.equal(typeof registered.callback, 'function');
});

test('hides the window and returns true so the system does not close it', (t) => {
  const { registered, hidden } = register(staged(t), { xcomponentId: 'xc_7' });
  assert.equal(registered.callback(), true);
  assert.deepEqual(hidden, [7]);
});

test('does not hide and lets the close through while the window has no id yet', (t) => {
  const { registered, hidden } = register(staged(t), { xcomponentId: '' });
  assert.equal(registered.callback(), false);
  assert.deepEqual(hidden, []);
});

test('the only return false is the guard for a window without an id', (t) => {
  const body = injectedLines(staged(t)).join('\n');
  assert.equal((body.match(/return false;/g) || []).length, 1);
  assert.ok(body.indexOf('return false;') < body.indexOf('hideWindow('));
  assert.ok(body.lastIndexOf('return true;') > body.indexOf('hideWindow('));
});

test('the staging script fails loudly when the template has no such line', (t) => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'codex-stage-'));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  template(path.join(dir, 'template'));
  fs.writeFileSync(path.join(dir, 'template', WEB_ABILITY), 'export default class WebAbility {}\n');
  const result = childProcess.spawnSync('bash', [stage, path.join(dir, 'template'), path.join(dir, 'out'), '26.1117.41037'], { encoding: 'utf8' });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /expected one/);
});
