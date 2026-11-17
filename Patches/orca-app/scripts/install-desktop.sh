#!/usr/bin/env bash
# Inject the host connection config into the shell HAP, sign it and install it.
#
# The bottle HAP is unsigned and carries only a placeholder config.json; this
# script writes the real connection settings (the loopback port and the web
# client URL with its pairing code) into a copy of the HAP, optionally swaps in
# the ACL module.json, and signs it with a locally generated debug profile
# through app-installer.
#
# Default variant is the ACL one (the two kernel JIT ACLs keep WebAssembly
# available in the renderer, READ_PASTEBOARD makes paste work). --no-acl
# installs the strong-sandbox variant for debugging.
set -euo pipefail

BUNDLE_ID="${ORCA_DESKTOP_BUNDLE:-com.social4hyq.orca}"
APP_NAME="${ORCA_DESKTOP_APP_NAME:-Orca}"
SHELL_HAP="${ORCA_DESKTOP_UNSIGNED_HAP:?set ORCA_DESKTOP_UNSIGNED_HAP}"
MODULE_ACL="${ORCA_DESKTOP_MODULE_ACL:-}"
HDC="${ORCA_DESKTOP_HDC:-${ORCA_DESKTOP_HDC_DEFAULT:-hdc}}"
HAP_CONFIG="resources/resfile/resources/app/config.json"
CONFIG=""
WANT_ACL=1
KEEP=0

usage() {
  cat <<'EOF'
Usage: orca-app install --config PATH [--no-acl] [--keep]

  --config PATH  Host config written by `orca-app serve` (port, web client URL).
  --no-acl       Install the strong-sandbox variant (no JIT, no paste).
  --keep         Keep the signed HAP (path printed on success).

Installs over hdc. The device must be connected and unlocked; the first ACL
install asks for a Huawei Developer login to generate the local debug profile.
EOF
}

log() { printf '%s\n' "$*" >&2; }
die() { log "error: $*"; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --config) CONFIG="${2:?--config needs a path}"; shift 2 ;;
    --hap) SHELL_HAP="${2:?--hap needs a path}"; shift 2 ;;
    --no-acl) WANT_ACL=0; shift ;;
    --keep) KEEP=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[ -n "$CONFIG" ] && [ -f "$CONFIG" ] || die "host config not found: ${CONFIG:-<unset>}"
[ -f "$SHELL_HAP" ] || die "shell HAP not found: $SHELL_HAP"
command -v node >/dev/null || die "node not found"
command -v zip >/dev/null || die "zip not found"
command -v app-installer >/dev/null || die "app-installer not found"

ACL=0
if [ "$WANT_ACL" = "1" ] && [ -n "$MODULE_ACL" ] && [ -f "$MODULE_ACL" ]; then
  ACL=1
elif [ "$WANT_ACL" = "1" ]; then
  log "warning: ACL module.json missing; falling back to the strong-sandbox HAP"
fi

# The ACL module.json replaces the HAP's own module.json; a bundle mismatch
# surfaces as an unreadable 9568329 on the device, so catch it here.
if [ "$ACL" = "1" ]; then
  hap_bundle="$(unzip -p "$SHELL_HAP" module.json | node -e 'let s=""; process.stdin.on("data",c=>s+=c).on("end",()=>process.stdout.write(JSON.parse(s).app.bundleName))')"
  acl_bundle="$(node -e 'process.stdout.write(JSON.parse(require("node:fs").readFileSync(process.argv[1],"utf8")).app.bundleName)' "$MODULE_ACL")"
  [ "$hap_bundle" = "$acl_bundle" ] || die "module-acl.json targets $acl_bundle but the HAP is $hap_bundle"
fi

stage="$(mktemp -d "${TMPDIR:-$HOME/.cache}/orca-app-inject.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
injected="$stage/orca-app-injected.hap"
signed="$stage/orca-app-signed.hap"
cp "$SHELL_HAP" "$injected"

mkdir -p "$stage/tree/$(dirname "$HAP_CONFIG")"
node - "$CONFIG" "$stage/tree/$HAP_CONFIG" <<'JS'
const fs = require("node:fs");
const [source, destination] = process.argv.slice(2);
const config = JSON.parse(fs.readFileSync(source, "utf8"));
if (!Number.isInteger(config.port) || config.port < 1 || config.port > 65535) throw new Error("invalid server port");
if (typeof config.url !== "string" || !config.url.startsWith("http://127.0.0.1:" + config.port + "/")) {
  throw new Error("invalid web client URL");
}
fs.writeFileSync(destination, JSON.stringify({ port: config.port, url: config.url }) + "\n");
JS

if [ "$ACL" = "1" ]; then
  cp "$MODULE_ACL" "$stage/tree/module.json"
  (cd "$stage/tree" && zip -q -X "$injected" module.json "$HAP_CONFIG")
else
  (cd "$stage/tree" && zip -q -X "$injected" "$HAP_CONFIG")
fi

# Stream app-installer's output instead of capturing it: the Huawei login URL
# and progress lines must reach the terminal while the command is still running.
log "signing and installing; a first-time Huawei Developer login prints a URL below"
if ! app-installer --hap "$injected" --bundle-id "$BUNDLE_ID" \
    --app-name "$APP_NAME" --module electron --ability EntryAbility \
    --signed-hap "$signed" --hdc "$HDC" 2>&1 | sed '/^FileTransfer/d' >&2; then
  die "installation failed"
fi

if [ "$KEEP" = "1" ]; then
  keep="${TMPDIR:-/tmp}/orca-app-signed.hap"
  cp "$signed" "$keep"
  log "signed HAP kept at $keep"
fi
variant="strong-sandbox"
if [ "$ACL" = "1" ]; then variant="ACL"; fi
# The result line goes to stdout: callers (and `brew test`) read the command's
# stdout, while progress/diagnostics stay on stderr.
printf 'installed (%s, %s)\n' "$BUNDLE_ID" "$variant"
