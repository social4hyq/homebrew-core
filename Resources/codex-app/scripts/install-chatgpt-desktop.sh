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

# The bottle ships the shell only; the official package comes from OpenAI at
# install time (or from --deb) and stays in the user's cache.
EXTRA_TOOLS=(curl)
VENDOR_DEB="${CHATGPT_APP_VENDOR_DEB:-}"
CLEAN_CACHE=0
DEFAULT_HAP="${CHATGPT_APP_UNSIGNED_HAP:-}"

app_usage_extra() {
  cat <<'EOF'
  --deb PATH     Official ChatGPT .deb to use instead of downloading it.
  --clean-cache  Remove the cached .deb and assembled HAP before installing.
EOF
}

app_parse_option() {
  case "${1:-}" in
    --deb)
      VENDOR_DEB="${2:?--deb needs a path}"
      OPT_SHIFT=2
      ;;
    --clean-cache)
      CLEAN_CACHE=1
      OPT_SHIFT=1
      ;;
    *) OPT_SHIFT=0 ;;
  esac
}

codex_cache_dir() {
  printf '%s' "${XDG_CACHE_HOME:-$HOME/.cache}/codex-app"
}

record_vendor_failure() { # stage reason detail
  [ -n "${HAP_INSTALLER_RESULT_FILE:-}" ] || return 0
  node -e '
const fs = require("node:fs");
const [file, stage, reason, detail] = process.argv.slice(1);
fs.writeFileSync(file, JSON.stringify({ v: 1, stage, reason, detail: String(detail).slice(0, 300) }) + "\n", { mode: 0o600 });
' "$HAP_INSTALLER_RESULT_FILE" "$1" "$2" "$3" 2>/dev/null || true
}

sha256_matches() {
  node -e '
const fs = require("node:fs"), crypto = require("node:crypto");
const [file, want] = process.argv.slice(1);
const hash = crypto.createHash("sha256");
fs.createReadStream(file)
  .on("data", chunk => hash.update(chunk))
  .on("error", () => process.exit(1))
  .on("end", () => process.exit(hash.digest("hex") === want ? 0 : 1));
' "$1" "$2"
}

prepare_chatgpt_hap() {
  local vendor_json assemble_dir cache_dir deb assembled shell_key url sha version file
  vendor_json="${CHATGPT_APP_VENDOR_JSON:?missing ChatGPT vendor.json}"
  assemble_dir="${CHATGPT_APP_ASSEMBLE_DIR:?missing the HAP assembler}"
  cache_dir="$(codex_cache_dir)"
  if [ "$CLEAN_CACHE" = "1" ]; then rm -rf "$cache_dir"; fi
  mkdir -p "$cache_dir/vendor" "$cache_dir/assembled"

  read -r url sha version file < <(node -e '
const value = JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"));
process.stdout.write([value.url, value.sha256, value.version, value.file || "chatgpt_arm64.deb"].join(" "));
' "$vendor_json")
  [ -n "$url" ] && [ -n "$sha" ] || { echo "invalid vendor.json: $vendor_json" >&2; exit 1; }

  if [ -n "$VENDOR_DEB" ]; then
    [ -f "$VENDOR_DEB" ] || { echo "--deb not found: $VENDOR_DEB" >&2; exit 1; }
    sha256_matches "$VENDOR_DEB" "$sha" || { echo "--deb failed the sha256 check: $VENDOR_DEB" >&2; exit 1; }
    deb="$VENDOR_DEB"
  else
    deb="$cache_dir/vendor/$sha.deb"
    if [ -f "$deb" ] && sha256_matches "$deb" "$sha"; then
      log "using the cached ChatGPT $version package"
    else
      rm -f "$deb" "$deb.part"
      log "downloading ChatGPT $version from OpenAI (~519 MB)..."
      curl -fL --retry 3 --retry-delay 2 -C - -o "$deb.part" "$url" ||
        { record_vendor_failure download network "download failed: $url"; echo "download failed: $url" >&2; exit 1; }
      mv "$deb.part" "$deb"
      if ! sha256_matches "$deb" "$sha"; then
        rm -f "$deb"
        record_vendor_failure download install-failed "downloaded package failed the sha256 check"
        echo "the downloaded package failed the sha256 check" >&2
        exit 1
      fi
    fi
  fi

  shell_key="$(node -e '
const crypto = require("node:crypto"), fs = require("node:fs");
const hash = crypto.createHash("sha256");
fs.createReadStream(process.argv[1])
  .on("data", chunk => hash.update(chunk))
  .on("end", () => process.stdout.write(hash.digest("hex").slice(0, 16)));
' "$DEFAULT_HAP")"
  assembled="$cache_dir/assembled/chatgpt-$shell_key-${sha:0:16}.hap"
  if [ -f "$assembled" ]; then
    log "using the cached assembled HAP"
  else
    rm -f "$assembled" "$assembled.part"
    log "assembling the HAP (this can take a minute)..."
    python3 "$assemble_dir/assemble-local-hap.py" "$DEFAULT_HAP" "$deb" "$assembled.part" >&2 ||
      { rm -f "$assembled.part"; record_vendor_failure assemble install-failed "assembling the HAP failed"; echo "assembling the HAP failed" >&2; exit 1; }
    mv "$assembled.part" "$assembled"
  fi
  printf '%s' "$assembled"
}

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

  case "$(basename "${shell_hap:-}")" in
    codex-app-shell-unsigned.hap) shell_hap="$(prepare_chatgpt_hap)" ;;
    *) log "using the caller's HAP as-is; skipping the ChatGPT package download" ;;
  esac
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
