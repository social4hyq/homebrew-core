'use strict';
const path = require('node:path');
const fs = require('node:fs');

// Claude Code stores workspace trust in ~/.claude.json by default. In an OHOS
// HAP, Node's homedir can resolve outside the app sandbox. Keep this state in
// Electron's app-private, persistent userData directory instead. Use a private
// temp directory too: host /tmp is not writable from an HAP.
function configureClaudeConfigDir(app, env = process.env) {
  const userData = app.getPath('userData');
  if (typeof userData !== 'string' || !path.isAbsolute(userData)) {
    throw new Error('Electron did not provide an app-private userData path');
  }
  const tempDir = path.join(userData, 'tmp');
  fs.mkdirSync(tempDir, { recursive: true, mode: 0o700 });
  env.CLAUDE_CONFIG_DIR = userData;
  env.TMPDIR = tempDir;
  return { userData, tempDir };
}

module.exports = { configureClaudeConfigDir };
