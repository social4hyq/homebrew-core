'use strict';
const assert = require('node:assert/strict');
const { EventEmitter } = require('node:events');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const vm = require('node:vm');
const test = require('node:test');

const HOST_HOME = '/storage/Users/currentUser';
const BREW_PREFIX = `${HOST_HOME}/.harmonybrew`;
const HOST_CLAUDE = `${BREW_PREFIX}/opt/claude-code.latest/bin/claude`;

function runLaunch(api = 'spawn', {
  exitCode = 0, stderrText = '', denyWorkspace = false, keepOpen = false,
  preflightCli = false, secondChildActive = false,
  claudeConfigDir = `${HOST_HOME}/.claude`, childEnv = { KEEP_ME: 'yes' },
} = {}) {
  const userData = fs.mkdtempSync(path.join(os.tmpdir(), 'claude-bootstrap-test-'));
  const workspace = fs.mkdtempSync(path.join(os.tmpdir(), 'claude-host-workspace-'));
  const makeChild = () => {
    const result = new EventEmitter();
    result.stderr = new EventEmitter();
    result.exitCode = null;
    result.signalCode = null;
    result.kill = signal => { result.signalCode = signal; };
    return result;
  };
  const child = makeChild();
  const secondChild = makeChild();
  const warnings = [];
  const diagnostics = [];
  const calls = [];
  const configCalls = [];
  const app = new EventEmitter();
  app.getPath = key => key === 'userData' ? userData : path.join(userData, 'tmp');
  app.setAppPath = () => {};
  app.whenReady = () => Promise.resolve();

  function baseSpawn(command, ...args) {
    if (args[0]?.[0] === '--version') {
      const probe = new EventEmitter();
      probe.stdout = new EventEmitter();
      probe.stderr = new EventEmitter();
      probe.kill = () => {};
      calls.push({ command, args, probe: true });
      process.nextTick(() => {
        probe.stdout.emit('data', Buffer.from('2.1.327 (Claude Code)\n'));
        probe.emit('close', 0, null);
      });
      return probe;
    }
    const index = calls.filter(call => !call.probe).length;
    calls.push({ command, args });
    return index === 0 ? child : secondChild;
  }
  const childProcess = { spawn: baseSpawn, execFile: baseSpawn, fork: baseSpawn };
  const electron = { app, dialog: { showMessageBox: async options => { warnings.push(options); return { response: 0 }; } } };
  const fakeFs = new Proxy(fs, { get(target, property) {
    if (property === 'accessSync') return (targetPath, mode) => {
      if (denyWorkspace && targetPath === workspace && (mode === fs.constants.R_OK || mode === fs.constants.W_OK)) {
        const error = new Error('denied'); error.code = 'EACCES'; throw error;
      }
      return fs.accessSync(targetPath, mode);
    };
    return Reflect.get(target, property);
  }});
  const hostConfig = {
    home: HOST_HOME,
    brewPrefix: BREW_PREFIX,
    claude: HOST_CLAUDE,
    claudeConfigDir,
    path: `${BREW_PREFIX}/bin:${BREW_PREFIX}/sbin:/system/bin:/usr/bin`,
    xdg: {}, preflightCli,
  };
  const fakeRequire = name => {
    if (name === 'electron') return electron;
    if (name === 'node:path') return path;
    if (name === 'node:fs') return fakeFs;
    if (name === 'node:child_process') return childProcess;
    if (name === './claude-ohos-config.cjs') return {
      configureClaudeConfigDir(target, env, options) {
        configCalls.push({ env, options });
        // What the real module does for the main process when the host folder is usable.
        env.CLAUDE_CONFIG_DIR = options.hostConfigDir;
        const tempDir = path.join(target.getPath('userData'), 'tmp');
        fs.mkdirSync(tempDir, { recursive: true });
        return { userData: target.getPath('userData'), tempDir };
      },
    };
    if (name === './claude-host-config.json') return hostConfig;
    if (name === './claude-launch-bridge.cjs') return { startClaudeLaunchBridge() {} };
    if (name === path.join('/app/vendor.asar', 'package.json')) return { main: 'main.cjs' };
    if (name === path.join('/app/vendor.asar', 'main.cjs')) {
      childProcess[api](HOST_CLAUDE, ['--print', 'NEVER_LOG_THIS_PROMPT'], { cwd: workspace, env: { ...childEnv } });
      if (secondChildActive) {
        childProcess[api](HOST_CLAUDE, ['--print', 'SECOND_PROMPT'], { cwd: workspace });
      }
      if (stderrText) child.stderr.emit('data', Buffer.from(stderrText));
      if (!keepOpen) {
        child.exitCode = exitCode;
        child.emit('close', exitCode, null);
      }
      return {};
    }
    throw new Error(`unexpected require: ${name}`);
  };
  const code = fs.readFileSync(path.join(__dirname, 'claude-bootstrap.cjs'), 'utf8');
  const processStub = { env: {}, platform: 'openharmony', arch: 'arm64' };
  vm.runInNewContext(code, {
    require: fakeRequire,
    process: processStub,
    __dirname: '/app',
    console: { warn: message => diagnostics.push(message) },
    Buffer,
    setTimeout,
    clearTimeout,
  }, { filename: 'claude-bootstrap.cjs' });
  return { userData, workspace, warnings, diagnostics, calls, configCalls, processStub, app, child, secondChild };
}

for (const api of ['spawn', 'execFile', 'fork']) {
  test(`injects host Homebrew environment into child_process.${api} without prompting for a token`, () => {
    const state = runLaunch(api);
    const { userData, workspace, calls, processStub, warnings } = state;
    assert.equal(processStub.env.CLAUDE_CODE_LOCAL_BINARY, HOST_CLAUDE);
    assert.equal(calls.length, 1);
    assert.equal(calls[0].command, HOST_CLAUDE);
    assert.deepEqual(Array.from(calls[0].args[0]), ['--print', 'NEVER_LOG_THIS_PROMPT']);
    const options = calls[0].args[1];
    assert.equal(options.cwd, workspace);
    assert.equal(options.env.HOME, HOST_HOME);
    assert.equal(options.env.HOMEBREW_PREFIX, BREW_PREFIX);
    assert.equal(options.env.PATH, `${BREW_PREFIX}/bin:${BREW_PREFIX}/sbin:/system/bin:/usr/bin`);
    assert.equal('CLAUDE_CONFIG_DIR' in options.env, false, 'the default folder needs no variable');
    assert.equal(options.env.TMPDIR, path.join(userData, 'tmp'));
    assert.equal(options.env.CLAUDE_CODE_TMPDIR, path.join(userData, 'tmp'));
    assert.equal(options.env.KEEP_ME, 'yes');
    assert.deepEqual(warnings, []);
    assert.ok(fs.readFileSync(path.join(userData, 'claude-code-launch-diagnostics.txt'), 'utf8').includes('host-homebrew-claude'));
    fs.rmSync(userData, { recursive: true, force: true });
    fs.rmSync(workspace, { recursive: true, force: true });
  });
}

test('keeps the chosen workspace and never falls back to token pairing when ACL access fails', async () => {
  const state = runLaunch('spawn', { exitCode: 126, denyWorkspace: true, stderrText: 'Permission denied: NEVER_LOG_THIS_PROMPT' });
  const { userData, workspace, calls, warnings, child } = state;
  assert.equal(calls[0].args[1].cwd, workspace);
  await new Promise(resolve => setImmediate(resolve));
  assert.equal(warnings.length, 1);
  assert.deepEqual(Array.from(warnings[0].buttons), ['关闭']);
  const log = fs.readFileSync(path.join(userData, 'claude-code-launch-diagnostics.txt'), 'utf8');
  assert.match(log, /cwd=directory,read=EACCES,write=EACCES,execute=true/);
  assert.doesNotMatch(log, /NEVER_LOG_THIS_PROMPT|TOKEN|39173/);
  fs.rmSync(userData, { recursive: true, force: true });
  fs.rmSync(workspace, { recursive: true, force: true });
});

test('does not show a fatal dialog for exit 143 while a replacement Claude child remains active', async () => {
  const state = runLaunch('spawn', { exitCode: 143, secondChildActive: true });
  await new Promise(resolve => setImmediate(resolve));
  assert.equal(state.warnings.length, 0);
  assert.equal(state.secondChild.exitCode, null);
  fs.rmSync(state.userData, { recursive: true, force: true });
  fs.rmSync(state.workspace, { recursive: true, force: true });
});

test('still shows a fatal dialog for exit 143 when no replacement Claude child is active', async () => {
  const state = runLaunch('spawn', { exitCode: 143 });
  await new Promise(resolve => setImmediate(resolve));
  assert.equal(state.warnings.length, 1);
  fs.rmSync(state.userData, { recursive: true, force: true });
  fs.rmSync(state.workspace, { recursive: true, force: true });
});

test('terminates active host CLI children when the shell quits', () => {
  const state = runLaunch('spawn', { keepOpen: true });
  state.app.emit('before-quit');
  assert.equal(state.child.signalCode, 'SIGTERM');
  fs.rmSync(state.userData, { recursive: true, force: true });
  fs.rmSync(state.workspace, { recursive: true, force: true });
});

test('runs an optional side-effect-free host CLI version preflight and redacts output to the version', async () => {
  const state = runLaunch('spawn', { preflightCli: true });
  await new Promise(resolve => setImmediate(resolve));
  const log = fs.readFileSync(path.join(state.userData, 'claude-code-launch-diagnostics.txt'), 'utf8');
  assert.match(log, /startup-cli-probe version=2\.1\.327 exit=0 signal=none stderr=no-stderr/);
  assert.equal(state.calls.filter(call => call.probe).length, 1);
  assert.doesNotMatch(log, /NEVER_LOG_THIS_PROMPT|\.claude\/|storage\/Users/);
  fs.rmSync(state.userData, { recursive: true, force: true });
  fs.rmSync(state.workspace, { recursive: true, force: true });
});

test('the child uses the terminal\'s own config: no CLAUDE_CONFIG_DIR for the default ~/.claude, even when the main process has one', () => {
  const state = runLaunch('spawn', { childEnv: { KEEP_ME: 'yes', CLAUDE_CONFIG_DIR: '/app/private/userData' } });
  const options = state.calls[0].args[1];
  assert.equal('CLAUDE_CONFIG_DIR' in options.env, false);
  assert.equal(options.env.HOME, HOST_HOME);
  fs.rmSync(state.userData, { recursive: true, force: true });
});

test('a config folder that is not the default is still passed to the child', () => {
  const state = runLaunch('spawn', { claudeConfigDir: `${HOST_HOME}/work/claude-config` });
  assert.equal(state.calls[0].args[1].env.CLAUDE_CONFIG_DIR, `${HOST_HOME}/work/claude-config`);
  fs.rmSync(state.userData, { recursive: true, force: true });
});

test('the main process is given the host config folder to use when it can', () => {
  const state = runLaunch('spawn');
  assert.equal(state.configCalls.length, 1);
  assert.deepEqual({ ...state.configCalls[0].options }, { hostConfigDir: `${HOST_HOME}/.claude`, defaultConfigDir: `${HOST_HOME}/.claude` });
  assert.equal(state.configCalls[0].env, state.processStub.env);
  const custom = runLaunch('spawn', { claudeConfigDir: `${HOST_HOME}/work/claude-config` });
  assert.equal(custom.configCalls[0].options.hostConfigDir, `${HOST_HOME}/work/claude-config`);
  fs.rmSync(state.userData, { recursive: true, force: true });
  fs.rmSync(custom.userData, { recursive: true, force: true });
});

test('the version probe gets the same environment as the sessions', () => {
  const state = runLaunch('spawn', { preflightCli: true });
  const probe = state.calls.find((call) => call.probe);
  assert.ok(probe);
  assert.equal(probe.args[1].env.HOME, HOST_HOME);
  assert.equal('CLAUDE_CONFIG_DIR' in probe.args[1].env, false);
  fs.rmSync(state.userData, { recursive: true, force: true });
});
