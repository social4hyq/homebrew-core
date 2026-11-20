#!/usr/bin/env bash
# Inject this host's stable Codex CLI paths, then sign and install a HAP copy.
set -euo pipefail

APP_CMD=codex-app
ENV_PREFIX=CHATGPT_APP
BUNDLE_ID_DEFAULT=com.social4hyq.chatgpt
APP_NAME_DEFAULT=ChatGPT
NEED_CONFIG=0
MODULE=electron
ABILITY=EntryAbility

app_prepare() {
  local home prefix cli
  home="${CHATGPT_APP_HOST_HOME:-$HOME}"
  prefix="${CHATGPT_APP_BREW_PREFIX:-${HOMEBREW_PREFIX:-$home/.harmonybrew}}"
  cli="${CHATGPT_APP_CODEX_CLI:-$prefix/opt/codex/bin/codex}"
  [[ -x "$cli" ]] || { echo "Homebrew Codex CLI missing or not executable: $cli" >&2; exit 1; }
  export CHATGPT_APP_HOST_HOME="$home" CHATGPT_APP_CODEX_CLI="$cli"
  export CHATGPT_APP_CODEX_HOME="${CODEX_HOME:-$home/.codex}"
  export CHATGPT_APP_HOST_PATH="$prefix/bin:$prefix/sbin:/system/bin:/system/xbin:/usr/bin:/bin:/vendor/bin"
  # Host Node and its OHOS node-pty back the in-app terminal (owl-pty-shim.cjs).
  export CHATGPT_APP_NODE="${CHATGPT_APP_NODE:-$prefix/opt/node/bin/node}"
  prepare_host_settings "$home" "$CHATGPT_APP_CODEX_HOME"
}

# HAP processes do not inherit the user's shell, and cannot create folders under
# ~/Documents.  Prepare the two host-side settings the shims rely on.  Both
# steps are idempotent and never overwrite what the user already has.
prepare_host_settings() {
  node - "$1" "$2" <<'JS'
const fs = require('node:fs');
const path = require('node:path');
const [home, codexHome] = process.argv.slice(2);

// 1. Proxy variables for the Codex CLI, the cloud websocket and terminals.
const envFile = path.join(home, '.config', 'codex-app', 'env.json');
if (fs.existsSync(envFile)) {
  console.log('codex-app: keeping existing ' + envFile);
} else {
  const names = ['HTTP_PROXY', 'HTTPS_PROXY', 'http_proxy', 'https_proxy', 'NO_PROXY', 'no_proxy'];
  const env = {};
  for (const name of names) if (process.env[name]) env[name] = process.env[name];
  if (Object.keys(env).length > 0) {
    fs.mkdirSync(path.dirname(envFile), { recursive: true });
    fs.writeFileSync(envFile, JSON.stringify(env, null, 1) + '\n', { flag: 'wx', mode: 0o600 });
    console.log('codex-app: created ' + envFile + ' with ' + Object.keys(env).join(', '));
  }
}

// 2. Default workspace root: the app creates <root>/<date>/<chat> and the HAP
//    cannot mkdir below ~/Documents, so point it at a folder the HAP can write.
const root = path.join(home, '.cache', 'codex-app', 'Documents', 'Codex');
fs.mkdirSync(root, { recursive: true });
fs.mkdirSync(codexHome, { recursive: true });
const config = path.join(codexHome, 'config.toml');
const entry = 'projectlessWorkspaceRoot = "' + root + '"\n';
let lines = fs.existsSync(config) ? fs.readFileSync(config, 'utf8').split(/(?<=\n)/) : [];
if (lines.length > 0 && !fs.existsSync(config + '.pre-owl')) fs.copyFileSync(config, config + '.pre-owl');
const out = [];
let inDesktop = false;
let written = false;
for (const line of lines) {
  const trimmed = line.trim();
  if (trimmed.startsWith('[')) {
    inDesktop = trimmed === '[desktop]';
    out.push(line);
    if (inDesktop && !written) { out.push(entry); written = true; }
    continue;
  }
  if (inDesktop && trimmed.startsWith('projectlessWorkspaceRoot')) continue;
  out.push(line);
}
if (!written) {
  if (out.length > 0 && !out[out.length - 1].endsWith('\n')) out[out.length - 1] += '\n';
  out.push('\n[desktop]\n', entry);
}
fs.writeFileSync(config + '.owl-tmp', out.join(''));
fs.renameSync(config + '.owl-tmp', config);
JS
}

stage_tree() {
  local _unused="$1" tree="$2"
  mkdir -p "$tree/resources/resfile/resources/app"
  node - "$tree/resources/resfile/resources/app/chatgpt-host-config.json" <<'JS'
const fs = require('node:fs');
const path = require('node:path');
const required = (name, value) => {
  if (typeof value !== 'string' || !path.isAbsolute(value)) throw new Error(`invalid host path: ${name}`);
  return value;
};
const config = {
  home: required('HOME', process.env.CHATGPT_APP_HOST_HOME),
  codexCli: required('Codex CLI', process.env.CHATGPT_APP_CODEX_CLI),
  codexHome: required('CODEX_HOME', process.env.CHATGPT_APP_CODEX_HOME),
  path: process.env.CHATGPT_APP_HOST_PATH || '',
};
// Optional terminal backend: present only when the paths are usable.
for (const [key, value] of [['nodeCli', process.env.CHATGPT_APP_NODE],
                            ['nodePtyDir', process.env.CHATGPT_APP_NODE_PTY]]) {
  if (typeof value === 'string' && path.isAbsolute(value)) config[key] = value;
}
fs.writeFileSync(process.argv[2], JSON.stringify(config) + '\n', { mode: 0o600 });
JS
}

. "$(dirname "${BASH_SOURCE[0]}")/hap-app-install-lib.sh"
