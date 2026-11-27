'use strict';

// OpenHarmony Claude Desktop shell. The installer injects a per-host config
// into the signed HAP (see claude-host-config.json). With the local ACL profile
// the Electron process can spawn the stable Homebrew opt launcher directly;
// there is no separately started daemon and no manually exchanged token.
const { app, dialog } = require('electron');
const path = require('node:path');
const fs = require('node:fs');
const vendor = path.join(__dirname, 'vendor.asar');
const claudeConfig = require('./claude-ohos-config.cjs');
const hostConfig = require('./claude-host-config.json');

function requireAbsolute(value, label) {
  if (typeof value !== 'string' || !path.isAbsolute(value)) {
    throw new Error(`invalid host config: ${label} must be an absolute path`);
  }
  return value;
}

const hostHome = requireAbsolute(hostConfig.home, 'home');
const brewPrefix = requireAbsolute(hostConfig.brewPrefix, 'brewPrefix');
const launcher = requireAbsolute(hostConfig.claude, 'claude');
const hostPath = typeof hostConfig.path === 'string' && hostConfig.path.length
  ? hostConfig.path
  : `${brewPrefix}/bin:${brewPrefix}/sbin:/system/bin:/system/xbin:/usr/bin:/bin:/vendor/bin`;
const hostXdg = hostConfig.xdg && typeof hostConfig.xdg === 'object' ? hostConfig.xdg : {};
const hostConfigDir = typeof hostConfig.claudeConfigDir === 'string' && path.isAbsolute(hostConfig.claudeConfigDir)
  ? hostConfig.claudeConfigDir
  : path.join(hostHome, '.claude');
// The default folder is the one a terminal's `claude` uses without any variable, and
// then its global state (user-scope MCP servers, workspace trust) is ~/.claude.json,
// not ~/.claude/.claude.json, which the CLI uses once CLAUDE_CONFIG_DIR is set.
// So the child gets the variable only for a folder that is not the default.
const hostDefaultConfigDir = path.join(hostHome, '.claude');
// The main process uses the same folder when the app may (see claude-ohos-config.cjs).
const appPaths = claudeConfig.configureClaudeConfigDir(app, process.env, { hostConfigDir, defaultConfigDir: hostDefaultConfigDir });

// Code Desktop's manager consumes this override when resolving its local CLI.
// Only the spawned CLI receives host HOME/PATH/config: Electron itself keeps
// all cookies and app state inside its private userData directory.
process.env.CLAUDE_CODE_LOCAL_BINARY = launcher;

const childProcess = require('node:child_process');
const originalSpawn = childProcess.spawn;
const originalExecFile = childProcess.execFile;
const originalFork = childProcess.fork;
const diagnosticFile = path.join(app.getPath('userData'), 'claude-code-launch-diagnostics.txt');
const activeChildren = new Set();
let failureDialogShown = false;

function writeDiagnostic(line) {
  try { fs.appendFileSync(diagnosticFile, `${new Date().toISOString()} ${line}\n`, { encoding: 'utf8', mode: 0o600 }); } catch {}
  // Diagnostics intentionally contain only fixed labels, status codes, and
  // access categories. Never log argv, prompt text, environment, or stderr.
  try { console.warn(`[claude-code-diagnostic] ${line}`); } catch {}
}

function stderrClass(text) {
  if (/permission denied|eacces/i.test(text)) return 'permission-denied';
  if (/no such file|enoent/i.test(text)) return 'file-not-found';
  if (/shared object|cannot load|loader/i.test(text)) return 'runtime-loader';
  if (/unsupported platform/i.test(text)) return 'unsupported-platform';
  return 'other-stderr';
}

function isClaudeCommand(command) {
  if (typeof command !== 'string') return false;
  const base = path.basename(command);
  return command === launcher || /^claude(?:$|[-.])/i.test(base);
}

function optionIndex(args) {
  return args.findIndex(value => value && typeof value === 'object' && !Array.isArray(value));
}

function hostEnvironment(inherited = process.env) {
  const env = { ...inherited };
  env.HOME = hostHome;
  env.HOMEBREW_PREFIX = brewPrefix;
  env.PATH = hostPath;
  if (hostConfigDir === hostDefaultConfigDir) delete env.CLAUDE_CONFIG_DIR;
  else env.CLAUDE_CONFIG_DIR = hostConfigDir;
  // Keep temporary state on the app's local filesystem; do not inherit the
  // host terminal's sandbox-local XDG/TMPDIR values.
  env.TMPDIR = appPaths.tempDir;
  env.CLAUDE_CODE_TMPDIR = appPaths.tempDir;
  for (const [configKey, envKey] of [['config', 'XDG_CONFIG_HOME'], ['data', 'XDG_DATA_HOME'], ['state', 'XDG_STATE_HOME']]) {
    const value = hostXdg[configKey];
    if (typeof value === 'string' && value.length) env[envKey] = value;
    else delete env[envKey];
  }
  return env;
}

function hostLaunchArgs(args) {
  const cloned = args.slice();
  let index = optionIndex(cloned);
  if (index < 0) {
    // Node child_process signatures accept either args+options or options
    // alone. Preserve an existing positional args array when adding options.
    if (cloned.length && Array.isArray(cloned[0])) cloned.push({});
    else { cloned.unshift([]); cloned.push({}); }
    index = cloned.length - 1;
  }
  const original = cloned[index];
  const env = hostEnvironment(original.env || process.env);
  cloned[index] = { ...original, env };
  return cloned;
}

function spawnCwd(args) {
  const index = optionIndex(args);
  return index < 0 ? undefined : args[index]?.cwd;
}

function checkSpawnCwd(options) {
  const cwd = options?.cwd;
  if (typeof cwd !== 'string' || cwd === '') return 'cwd=default';
  try {
    const info = fs.statSync(cwd);
    if (!info.isDirectory()) return 'cwd=not-directory';
    const access = {};
    for (const [label, mode] of [['read', fs.constants.R_OK], ['write', fs.constants.W_OK], ['execute', fs.constants.X_OK]]) {
      try { fs.accessSync(cwd, mode); access[label] = 'true'; }
      catch (error) { access[label] = typeof error?.code === 'string' ? error.code : 'denied'; }
    }
    return `cwd=directory,read=${access.read},write=${access.write},execute=${access.execute}`;
  } catch (error) {
    const code = typeof error?.code === 'string' ? error.code : 'unknown';
    return `cwd-check=${code}`;
  }
}

function showFailure(detail) {
  if (failureDialogShown) return;
  failureDialogShown = true;
  app.whenReady().then(() => dialog.showMessageBox({
    type: 'warning',
    title: 'Claude Code 无法启动',
    message: 'Claude Code 子进程未能正常启动。',
    detail: `${detail}\n请确认本机 Homebrew Claude Code 已安装，并在安装时授予的 ACL 权限仍有效。脱敏诊断保存在应用私有数据目录。`,
    buttons: ['关闭'], defaultId: 0, cancelId: 0,
  })).catch(() => {});
}

function monitorChild(child, command, args) {
  if (!child || typeof child.once !== 'function') return child;
  const label = command === launcher ? 'host-homebrew-claude' : path.basename(command).slice(0, 80);
  const cwdState = checkSpawnCwd({ cwd: spawnCwd(args) });
  writeDiagnostic(`launch-attempt command=${label} ${cwdState}`);
  activeChildren.add(child);
  child.once('error', error => {
    activeChildren.delete(child);
    const code = typeof error?.code === 'string' ? error.code : 'unknown';
    writeDiagnostic(`spawn-error code=${code}`);
    showFailure(`command=${label}, spawn error: ${code}, ${cwdState}`);
  });
  let stderrKind = 'no-stderr';
  if (child.stderr) child.stderr.on('data', chunk => { stderrKind = stderrClass(chunk.toString('utf8')); });
  child.once('close', (code, signal) => {
    activeChildren.delete(child);
    writeDiagnostic(`process-close code=${code === null ? 'null' : code} signal=${signal || 'none'} stderr=${stderrKind}`);
    // The OHOS compatibility shim can translate a terminated child into exit
    // code 143 instead of exposing SIGTERM. Claude Desktop starts replacement
    // CLI children during session initialization; don't show a fatal startup
    // dialog when another host CLI child is still running successfully.
    const replacedByActiveChild = code === 143 && !signal && activeChildren.size > 0;
    if (code !== 0 && !replacedByActiveChild) {
      showFailure(`command=${label}, exit=${code === null ? 'unknown' : code}, signal=${signal || 'none'}, stderr=${stderrKind}, ${cwdState}`);
    }
  });
  return child;
}

for (const [name, original] of [['spawn', originalSpawn], ['execFile', originalExecFile], ['fork', originalFork]]) {
  childProcess[name] = function(command, ...args) {
    const forwarded = isClaudeCommand(command) ? hostLaunchArgs(args) : args;
    const child = original.call(this, command, ...forwarded);
    return isClaudeCommand(command) ? monitorChild(child, command, forwarded) : child;
  };
}

app.on('before-quit', () => {
  for (const child of activeChildren) {
    if (child.exitCode === null && child.signalCode === null) {
      try { child.kill('SIGTERM'); } catch {}
    }
  }
});

// Read-only launcher probe: no auth, workspace, or user content is accessed.
try {
  fs.accessSync(launcher, fs.constants.X_OK);
  writeDiagnostic('startup-launcher-check host-homebrew-launcher=executable');
} catch (error) {
  writeDiagnostic(`startup-launcher-check host-homebrew-launcher=${typeof error?.code === 'string' ? error.code : 'denied'}`);
}

function verifyHostClaudeCLI() {
  if (hostConfig.preflightCli !== true) return;
  let child;
  let stdout = '';
  let stderrKind = 'no-stderr';
  try {
    child = originalSpawn.call(childProcess, launcher, ['--version'], {
      cwd: hostHome,
      env: hostEnvironment(process.env),
      stdio: ['ignore', 'pipe', 'pipe'],
    });
  } catch (error) {
    writeDiagnostic(`startup-cli-probe spawn-error=${typeof error?.code === 'string' ? error.code : 'unknown'}`);
    return;
  }
  const timer = setTimeout(() => {
    try { child.kill('SIGKILL'); } catch {}
    writeDiagnostic('startup-cli-probe timeout');
  }, 15000);
  timer.unref?.();
  child.stdout?.on('data', chunk => { stdout = (stdout + chunk.toString('utf8')).slice(-256); });
  child.stderr?.on('data', chunk => { stderrKind = stderrClass(chunk.toString('utf8')); });
  child.once('error', error => {
    clearTimeout(timer);
    writeDiagnostic(`startup-cli-probe spawn-error=${typeof error?.code === 'string' ? error.code : 'unknown'}`);
  });
  child.once('close', (code, signal) => {
    clearTimeout(timer);
    const version = /\b\d+\.\d+\.\d+\b/.exec(stdout)?.[0] || 'unknown';
    writeDiagnostic(`startup-cli-probe version=${version} exit=${Number.isInteger(code) ? code : 'unknown'} signal=${signal || 'none'} stderr=${stderrKind}`);
  });
}
verifyHostClaudeCLI();

app.setAppPath(vendor);
require('./claude-launch-bridge.cjs').startClaudeLaunchBridge();
require(path.join(vendor, require(path.join(vendor, 'package.json')).main));
