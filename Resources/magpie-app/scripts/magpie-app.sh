#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo 'Usage: magpie-app install [--no-acl] [--keep] [--device ID] | start | web [--port N] [--status]'
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
bundle=com.social4hyq.magpiedesktop
hdc="${MAGPIE_APP_HDC:-${MAGPIE_APP_HDC_DEFAULT:-hdc}}"
case "${1:---help}" in
  start)
    [[ $# == 1 ]] || { usage >&2; exit 2; }
    exec "$hdc" shell aa start -b "$bundle" -a EntryAbility -m electron
    ;;
  web)
    shift
    web_serve "$@"
    ;;
  install)
    shift
    exec "${MAGPIE_APP_INSTALL_SCRIPT:?formula did not set the install script path}" "$@"
    ;;
  -h|--help) usage ;;
  *) usage >&2; exit 2 ;;
esac
