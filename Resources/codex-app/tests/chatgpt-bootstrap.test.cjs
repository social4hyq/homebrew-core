'use strict';

const assert = require('node:assert/strict');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');
const fs = require('node:fs');

const source = fs.readFileSync(
  path.join(__dirname, '../app/chatgpt-bootstrap.cjs'), 'utf8',
);
const vendor = path.join(__dirname, 'vendor.asar');
const hostConfig = {
  home: '/storage/Users/currentUser',
  codexCli: '/storage/Users/currentUser/.harmonybrew/opt/codex/bin/codex',
  codexHome: '/storage/Users/currentUser/.codex',
  path: '/storage/Users/currentUser/.harmonybrew/bin:/system/bin',
};

function boot(packageVersion = '26.1117.41037', shellVersion = packageVersion) {
  const runtimeProcess = { env: {} };
  const state = {
    appPath: null,
    loaded: null,
    compatLoaded: false,
    order: [],
    tray: null,
    name: null,
    paths: {},
    madeDirs: [],
    childProcess: null,
    process: runtimeProcess,
  };
  const app = {
    getPath(name) {
      assert.equal(name, 'userData');
      return '/data/storage/el2/base/files/ChatGPT';
    },
    setAppPath(value) { state.appPath = value; },
    setName(value) { state.name = value; },
    setPath(name, value) { state.paths[name] = value; },
  };
  const childProcess = {};
  for (const name of ['spawn', 'spawnSync', 'execFile', 'execFileSync']) {
    childProcess[name] = (...args) => ({ called: name, args });
  }
  state.childProcess = childProcess;
  const fakeRequire = id => {
    if (id === 'node:path') return path;
    if (id === 'node:fs') {
      return {
        readFileSync: () => JSON.stringify(hostConfig),
        mkdirSync: (...args) => state.madeDirs.push(args),
      };
    }
    if (id === 'node:child_process') return childProcess;
    if (id === 'electron') return { app };
    if (id === './owl-compat.cjs') { state.compatLoaded = true; state.order.push('compat'); return {}; }
    if (id === './owl-share.cjs') {
      return {
        endpointFile: (home) => `${home}/.config/codex-app/server.json`,
        appOwnedServer: (file) => ({ file }),
      };
    }
    if (id === './owl-tray.cjs') {
      return { install: (electron, options) => { state.order.push('tray'); state.tray = { electron, options }; } };
    }
    if (id === vendor) return {};
    if (id === path.join(__dirname, 'package.json')) return { version: shellVersion };
    if (id === path.join(vendor, 'package.json')) {
      return { version: packageVersion, main: '.vite/build/early-bootstrap.js' };
    }
    if (id === path.join(vendor, '.vite/build/early-bootstrap.js')) {
      state.order.push('vendor');
      state.loaded = id;
      return {};
    }
    throw new Error(`unexpected require: ${id}`);
  };
  vm.runInNewContext(source, { require: fakeRequire, __dirname, process: runtimeProcess, console });
  return state;
}

test('loads the official app and configures the supported host Codex CLI override', () => {
  const state = boot();
  assert.equal(state.name, 'ChatGPT');
  assert.equal(state.appPath, vendor);
  assert.equal(state.paths.appData, '/data/storage/el2/base/files/ChatGPT');
  assert.equal(state.madeDirs.length, 1);
  assert.equal(state.madeDirs[0][0], '/data/storage/el2/base/files/ChatGPT');
  assert.equal(state.madeDirs[0][1].recursive, true);
  assert.equal(state.madeDirs[0][1].mode, 0o700);
  assert.equal(state.loaded, path.join(vendor, '.vite/build/early-bootstrap.js'));
  assert.equal(state.process.env.CODEX_CLI_PATH, hostConfig.codexCli);
  assert.equal(state.compatLoaded, true);
});

test('installs the tray before the vendor code can open a window', () => {
  const state = boot();
  assert.deepEqual(state.order, ['compat', 'tray', 'vendor']);
  assert.equal(state.tray.options.iconPath, path.join(__dirname, 'tray-icon.png'), 'next to the bootstrap in the HAP');
});

test('the tray asks about the shared server registered under the host home', () => {
  const state = boot();
  assert.deepEqual({ ...state.tray.options.ownedServer() }, { file: `${hostConfig.home}/.config/codex-app/server.json` });
});

test('launches Codex with host HOME, CODEX_HOME and PATH while preserving workspace cwd', () => {
  const state = boot();
  const child = state.childProcess.spawn('/usr/bin/codex', ['app-server'], {
    cwd: '/storage/Users/currentUser/HarmonyPC/Project',
    env: { HOME: '/sandbox/home', CODEX_HOME: '/sandbox/.codex', PATH: '/sandbox/bin' },
  });
  assert.equal(child.args[0], hostConfig.codexCli);
  assert.equal(child.args[2].cwd, '/storage/Users/currentUser/HarmonyPC/Project');
  assert.equal(child.args[2].env.HOME, hostConfig.home);
  assert.equal(child.args[2].env.CODEX_HOME, hostConfig.codexHome);
  assert.equal(child.args[2].env.PATH, hostConfig.path);
});

test('uses host HOME when the requested working directory is relative', () => {
  const state = boot();
  const child = state.childProcess.spawn(hostConfig.codexCli, ['app-server'], { cwd: 'relative' });
  assert.equal(child.args[2].cwd, hostConfig.home);
});

test('does not rewrite unrelated subprocesses', () => {
  const state = boot();
  const child = state.childProcess.spawn('/usr/bin/git', ['status']);
  assert.equal(child.args[0], '/usr/bin/git');
});

test('refuses an unexpected official package version', () => {
  assert.throws(() => boot('0.0.0', '26.1117.41037'), /unexpected official ChatGPT application entry point/);
});

test('refuses a vendor package that is not the version the shell was assembled for', () => {
  assert.throws(() => boot('26.1117.31558', '26.1117.41037'), /unexpected official ChatGPT application entry point/);
});

test('follows the assembled shell version instead of a fixed one', () => {
  const state = boot('99.1.2');
  assert.equal(state.loaded, path.join(vendor, '.vite/build/early-bootstrap.js'));
});
