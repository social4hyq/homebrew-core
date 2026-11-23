#!/usr/bin/env bash
set -euo pipefail

bundle=com.social4hyq.magpiedesktop
module=electron
ability=EntryAbility

usage() {
  cat <<'EOF'
Usage: magpie-app <command>

Commands:
  install [--no-acl] [--keep] [--device ID]
            Sign and install the desktop HAP (needs hdc and an unlocked device)
  start [--device ID]
            Open the app on the device
  stop [--device ID]
            Force-stop the app on the device
  status [--device ID]
            Show whether the app is running on the device
  uninstall [--device ID] [--purge]
            Remove the app from the device. The default keeps the app's data;
            --purge also deletes it.
  web [--port N] [--status]
            Run `magpie web` here (127.0.0.1:3431, a key kept in
            ~/.config/magpie-app/web-key) so the app opens it instead of
            starting a backend of its own; --status says whether one answers
  -h, --help  Show this help

Device options: --device ID picks the hdc target (default: HDC_TARGET, else
the first connected device).
EOF
}

hdc="${MAGPIE_APP_HDC:-${MAGPIE_APP_HDC_DEFAULT:-hdc}}"
app_installer="${MAGPIE_APP_INSTALLER:-app-installer}"
device_args=()
if [[ -n "${HDC_TARGET:-}" ]]; then
  device_args=(-t "$HDC_TARGET")
fi

parse_device() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --device)
        [[ $# -ge 2 && -n "$2" ]] || { printf 'magpie-app: --device needs an id\n' >&2; exit 2; }
        device_args=(-t "$2"); shift 2 ;;
      *) printf 'magpie-app: unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
  done
}

# `magpie web` with a key that stays the same, registered under the host home. The
# app opens that page instead of starting a backend of its own while it answers,
# so the terminal and the app use one gateway and one web UI.
WEB_DIR="$HOME/.config/magpie-app"
WEB_FILE="$WEB_DIR/web.json"
WEB_KEY_FILE="$WEB_DIR/web-key"
WEB_DEFAULT_PORT=3431
NODE="${MAGPIE_APP_NODE:-node}"

# The port that answers to the registered key, or nothing.
web_live_port() {
  [[ -f "$WEB_FILE" && -f "$WEB_KEY_FILE" ]] || return 0
  "$NODE" -e '
    const fs = require("node:fs");
    const port = Number(JSON.parse(fs.readFileSync(process.argv[1], "utf8")).port);
    const key = fs.readFileSync(process.argv[2], "utf8").trim();
    const request = require("node:http").get(`http://127.0.0.1:${port}/?k=${encodeURIComponent(key)}`,
      { timeout: 2000 }, (response) => { response.resume(); if (response.statusCode === 303 || response.statusCode === 200) process.stdout.write(String(port)); });
    request.on("timeout", () => request.destroy());
    request.on("error", () => {});
  ' "$WEB_FILE" "$WEB_KEY_FILE" 2>/dev/null || true
}

web_serve() {
  local port="$WEB_DEFAULT_PORT" status=0 live
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --port) port="${2:?--port needs a number}"; shift 2 ;;
      --status) status=1; shift ;;
      *) usage >&2; return 2 ;;
    esac
  done
  [[ "$port" =~ ^[1-9][0-9]{0,4}$ && "$port" -le 65535 ]] || { echo "magpie-app: bad port: $port" >&2; return 2; }
  live="$(web_live_port)"
  if [[ -n "$live" ]]; then
    echo "magpie-app: magpie web is already running at http://127.0.0.1:$live (the app opens it)"
    return 0
  fi
  if [[ "$status" == 1 ]]; then
    echo "magpie-app: no magpie web is registered, or it does not answer"
    return 1
  fi
  mkdir -p "$WEB_DIR"
  chmod 700 "$WEB_DIR"
  if [[ ! -s "$WEB_KEY_FILE" ]]; then
    (umask 077; "$NODE" -e 'process.stdout.write(require("node:crypto").randomBytes(32).toString("hex"))' >"$WEB_KEY_FILE")
  fi
  chmod 600 "$WEB_KEY_FILE"
  local key
  key="$(<"$WEB_KEY_FILE")"
  (umask 077; printf '{"version":1,"port":%s,"pid":%s}\n' "$port" "$$" >"$WEB_FILE")
  MAGPIE_WEB_KEY="$key" "${MAGPIE_APP_BIN:?formula did not set the magpie binary path}" web \
    --addr "127.0.0.1:$port" --no-open &
  local pid=$!
  trap 'kill "$pid" 2>/dev/null || true' INT TERM
  local code=0
  wait "$pid" || code=$?
  # A signal ends the first wait; wait again so the child is gone before the registration is.
  wait "$pid" 2>/dev/null || true
  if grep -q "\"pid\":$$[,}]" "$WEB_FILE" 2>/dev/null; then rm -f "$WEB_FILE"; fi
  return "$code"
}
case "${1:-}" in
  start)
    shift
    parse_device "$@"
    "${hdc}" "${device_args[@]}" shell aa start -b "$bundle" -a "$ability" -m "$module"
    ;;
  stop)
    shift
    parse_device "$@"
    "${hdc}" "${device_args[@]}" shell aa force-stop "$bundle"
    printf 'magpie-app: stopped %s\n' "$bundle"
    ;;
  status)
    shift
    parse_device "$@"
    # Match only app command names; unrelated shell arguments may mention the bundle.
    processes="$("${hdc}" "${device_args[@]}" shell "ps -ef" 2>/dev/null || true)"
    if printf '%s\n' "$processes" | awk -v bundle="$bundle" '
      $8 == bundle || index($8, bundle ":") == 1 { found = 1 }
      END { exit !found }
    '; then
      printf 'magpie-app: running (%s)\n' "$bundle"
    else
      printf 'magpie-app: not running (%s)\n' "$bundle" >&2
      exit 1
    fi
    ;;
  uninstall)
    shift
    purge=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --purge) purge=1; shift ;;
        --device)
          [[ $# -ge 2 && -n "$2" ]] || { printf 'magpie-app: --device needs an id\n' >&2; exit 2; }
          device_args=(-t "$2"); shift 2 ;;
        *) printf 'magpie-app: unknown option: %s\n' "$1" >&2; exit 2 ;;
      esac
    done
    # app-installer runs 'bm uninstall -k' unless --purge is given, so the
    # app's data survives a plain uninstall.
    args=(uninstall --bundle-id "$bundle")
    [[ ${#device_args[@]} -eq 0 ]] || args+=(--device "${device_args[1]}")
    [[ -z "$purge" ]] || args+=(--purge)
    "$app_installer" "${args[@]}"
    ;;
  web)
    shift
    web_serve "$@"
    ;;
  install)
    shift
    exec "${MAGPIE_APP_INSTALL_SCRIPT:?formula did not set the install script path}" "$@"
    ;;
  -h|--help|help) usage ;;
  *) usage >&2; exit 2 ;;
esac
