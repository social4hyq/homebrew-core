'use strict';
const path = require('node:path');
const fs = require('node:fs');

// Where the Electron main process keeps Claude Code's config. The official app's
// own code (session list, deleting a session, workspace trust) reads and writes
// $CLAUDE_CONFIG_DIR, the same folder the CLI child it starts uses for its
// transcripts, settings and credentials. The child runs with the host's ~/.claude,
// so when the app may use that folder (the ACL install grants the host home) the
// main process uses it too: both sides see the same sessions, and so does a
// terminal's `claude --resume`. Without access (the strong-sandbox install) the
// state stays in Electron's app-private, persistent userData directory, because in
// an OHOS HAP Node's homedir can resolve outside the app sandbox. A private temp
// directory is used too: host /tmp is not writable from an HAP.
function usableConfigDir(dir, fileSystem = fs) {
  if (typeof dir !== 'string' || !path.isAbsolute(dir)) return false;
  try {
    fileSystem.mkdirSync(dir, { recursive: true });
    fileSystem.accessSync(dir, fs.constants.R_OK | fs.constants.W_OK | fs.constants.X_OK);
    return true;
  } catch {
    return false;
  }
}

// options.hostConfigDir  the host's Claude config folder, when there is one
// options.fs             file system, for tests
function configureClaudeConfigDir(app, env = process.env, options = {}) {
  const userData = app.getPath('userData');
  if (typeof userData !== 'string' || !path.isAbsolute(userData)) {
    throw new Error('Electron did not provide an app-private userData path');
  }
  const tempDir = path.join(userData, 'tmp');
  fs.mkdirSync(tempDir, { recursive: true, mode: 0o700 });
  const shared = usableConfigDir(options.hostConfigDir, options.fs);
  env.CLAUDE_CONFIG_DIR = shared ? options.hostConfigDir : userData;
  env.TMPDIR = tempDir;
  return { userData, tempDir, configDir: env.CLAUDE_CONFIG_DIR, shared };
}

module.exports = { configureClaudeConfigDir, usableConfigDir };
