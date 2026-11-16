#!/usr/bin/env bash
# Stage application-specific config; hap-installer owns signing and deployment.
set -euo pipefail

usage() {
  printf '%s\n' 'Usage: install-desktop.sh --hap <unsigned.hap> --config <config.json> [--device <key>] [--no-acl]'
}
hap=
config=
device=
want_acl=1
while (($#)); do
  case "$1" in
    --hap|--config|--device)
      if (($# < 2)) || [[ -z "$2" || "$2" == --* ]]; then
        printf 'install-desktop: missing value for %s\n' "$1" >&2; exit 2
      fi
      case "$1" in
        --hap) hap="$2" ;;
        --config) config="$2" ;;
        --device) device="$2" ;;
      esac
      shift 2 ;;
    --no-acl) want_acl=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
[[ -f "$hap" && -f "$config" ]] || { usage >&2; exit 2; }
for tool in node zip hap-installer; do
  command -v "$tool" >/dev/null || { printf 'install-desktop: command not found: %s\n' "$tool" >&2; exit 1; }
done
hdc="${OPENCODE_DESKTOP_HDC:-${OPENCODE_DESKTOP_HDC_DEFAULT:-hdc}}"
backend="${OPENCODE_DESKTOP_OPENCODE_BIN:-$(command -v opencode || true)}"
[[ -n "$backend" && -x "$backend" ]] || { printf 'install-desktop: opencode not found\n' >&2; exit 1; }

stage="$(mktemp -d "${TMPDIR:-$HOME/.cache}/opencode-desktop-inject.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
injected="$stage/opencode-desktop.hap"
entry="resources/resfile/resources/app/config.json"
cp "$hap" "$injected"
mkdir -p "$stage/$(dirname "$entry")"
node - "$config" "$backend" "$stage/$entry" <<'JS'
const fs = require("node:fs");
const [source, backend, destination] = process.argv.slice(2);
const config = JSON.parse(fs.readFileSync(source, "utf8"));
if (!Number.isInteger(config.port) || config.port < 1 || config.port > 65535) throw new Error("invalid port");
if (typeof config.password !== "string" || !config.password) throw new Error("missing password");
const home = process.env.HOME;
const xdg = key => {
  const value = process.env[key] || "";
  return value.startsWith(home + "/") || value.startsWith("/storage/") ? value : "";
};
fs.writeFileSync(destination, JSON.stringify({port: config.port, password: config.password, opencode: backend,
  host: {home, path: process.env.PATH, xdgConfig: xdg("XDG_CONFIG_HOME"),
    xdgData: xdg("XDG_DATA_HOME"), xdgState: xdg("XDG_STATE_HOME")}}) + "\n");
JS
entries=("$entry")
if ((want_acl)); then
  module="${OPENCODE_DESKTOP_MODULE_ACL:?formula did not set the ACL module path}"
  [[ -f "$module" ]] || { printf 'install-desktop: ACL module missing: %s\n' "$module" >&2; exit 1; }
  cp "$module" "$stage/module.json"
  entries+=(module.json)
fi
(cd "$stage" && zip -q -X "$injected" "${entries[@]}")
args=(--hap "$injected" --bundle-id com.social4hyq.opencodedesktop --app-name OpenCodeDesktop --module electron --ability EntryAbility --hdc "$hdc")
if [[ -n "$device" ]]; then args+=(--device "$device"); fi
hap-installer "${args[@]}"
printf 'installed com.social4hyq.opencodedesktop\n'
