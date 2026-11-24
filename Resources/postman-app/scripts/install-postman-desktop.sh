#!/usr/bin/env bash
# Inject this host's paths + the official Postman payload, then sign and install
# a HAP copy under the weak sandbox. The bottle's HAP is never modified.
set -euo pipefail

APP_CMD=postman-app
ENV_PREFIX=POSTMAN_APP
BUNDLE_ID_DEFAULT=com.social4hyq.postman
APP_NAME_DEFAULT=Postman
NEED_CONFIG=0
MODULE=electron
ABILITY=EntryAbility

EXTRA_TOOLS=(curl)
VENDOR_TARBALL="${POSTMAN_APP_VENDOR_TARBALL:-}"
CLEAN_CACHE=0
DEFAULT_HAP="${POSTMAN_APP_UNSIGNED_HAP:-}"

app_usage_extra() {
  cat <<'EOF'
  --tarball PATH  Official Postman linux-arm64 tarball to use instead of downloading.
  --clean-cache   Remove the cached tarball and assembled HAP before installing.
EOF
}

app_parse_option() {
  case "${1:-}" in
    --tarball)
      VENDOR_TARBALL="${2:?--tarball needs a path}"
      OPT_SHIFT=2
      ;;
    --clean-cache)
      CLEAN_CACHE=1
      OPT_SHIFT=1
      ;;
    *) OPT_SHIFT=0 ;;
  esac
}

postman_cache_dir() {
  printf '%s' "${XDG_CACHE_HOME:-$HOME/.cache}/postman-app"
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

prepare_postman_hap() {
  local vendor_json assemble_dir cache_dir tarball assembled shell_key url sha version file
  vendor_json="${POSTMAN_APP_VENDOR_JSON:?missing Postman vendor.json}"
  assemble_dir="${POSTMAN_APP_ASSEMBLE_DIR:?missing the HAP assembler}"
  cache_dir="$(postman_cache_dir)"
  if [ "$CLEAN_CACHE" = "1" ]; then rm -rf "$cache_dir"; fi
  mkdir -p "$cache_dir/vendor" "$cache_dir/assembled"

  read -r url sha version file < <(node -e '
const value = JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"));
process.stdout.write([value.url, value.sha256, value.version, value.file || "postman-linux-arm64.tar.gz"].join(" "));
' "$vendor_json")
  [ -n "$url" ] && [ -n "$sha" ] || { echo "invalid vendor.json: $vendor_json" >&2; exit 1; }

  if [ -n "$VENDOR_TARBALL" ]; then
    [ -f "$VENDOR_TARBALL" ] || { echo "--tarball not found: $VENDOR_TARBALL" >&2; exit 1; }
    sha256_matches "$VENDOR_TARBALL" "$sha" || { echo "--tarball failed the sha256 check: $VENDOR_TARBALL" >&2; exit 1; }
    tarball="$VENDOR_TARBALL"
  else
    tarball="$cache_dir/vendor/$sha.tar.gz"
    if [ -f "$tarball" ] && sha256_matches "$tarball" "$sha"; then
      log "using the cached Postman $version package"
    else
      rm -f "$tarball" "$tarball.part"
      log "downloading Postman $version from postman.com (~200 MB)..."
      curl_tls_args=()
      if [ "${HAP_INSTALLER_TLS_INSECURE:-0}" = "1" ]; then
        curl_tls_args=(--insecure)
        log "warning: TLS certificate verification is disabled for the vendor download"
      fi
      curl "${curl_tls_args[@]}" -fL --retry 3 --retry-delay 2 -C - -o "$tarball.part" "$url" ||
        { record_vendor_failure download network "download failed: $url"; echo "download failed: $url" >&2; exit 1; }
      mv "$tarball.part" "$tarball"
      if ! sha256_matches "$tarball" "$sha"; then
        rm -f "$tarball"
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
  assembled="$cache_dir/assembled/postman-$shell_key-${sha:0:16}.hap"
  if [ -f "$assembled" ]; then
    log "using the cached assembled HAP"
  else
    rm -f "$assembled" "$assembled.part"
    log "assembling the HAP (this can take a minute)..."
    python3 "$assemble_dir/assemble-local-hap.py" "$DEFAULT_HAP" "$tarball" "$assembled.part" >&2 ||
      { rm -f "$assembled.part"; record_vendor_failure assemble install-failed "assembling the HAP failed"; echo "assembling the HAP failed" >&2; exit 1; }
    mv "$assembled.part" "$assembled"
  fi
  printf '%s' "$assembled"
}

app_prepare() {
  local home prefix host_path
  home="${POSTMAN_APP_HOST_HOME:-$HOME}"
  prefix="${POSTMAN_APP_BREW_PREFIX:-${HOMEBREW_PREFIX:-$home/.harmonybrew}}"
  export POSTMAN_APP_HOST_HOME="$home"
  host_path="$prefix/bin:$prefix/sbin:/system/bin:/system/xbin:/usr/bin:/bin:/vendor/bin"
  export POSTMAN_APP_HOST_PATH="$host_path"

  case "$(basename "${shell_hap:-}")" in
    postman-app-shell-unsigned.hap) shell_hap="$(prepare_postman_hap)" ;;
    *) log "using the caller's HAP as-is; skipping the Postman package download" ;;
  esac
}

stage_tree() {
  local _unused="$1" tree="$2"
  mkdir -p "$tree/resources/resfile/resources/app"
  node - "$tree/resources/resfile/resources/app/postman-host-config.json" <<'JS'
const fs = require('node:fs');
const path = require('node:path');
const required = (name, value) => {
  if (typeof value !== 'string' || !path.isAbsolute(value)) throw new Error(`invalid host path: ${name}`);
  return value;
};
const config = {
  home: required('HOME', process.env.POSTMAN_APP_HOST_HOME),
  path: process.env.POSTMAN_APP_HOST_PATH || '',
};
fs.writeFileSync(process.argv[2], JSON.stringify(config) + '\n', { mode: 0o600 });
JS
}

. "$(dirname "${BASH_SOURCE[0]}")/hap-app-install-lib.sh"
