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
fs.writeFileSync(process.argv[2], JSON.stringify(config) + '\n', { mode: 0o600 });
JS
}

. "$(dirname "${BASH_SOURCE[0]}")/hap-app-install-lib.sh"
