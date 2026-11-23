#!/usr/bin/env bash
set -euo pipefail

APP_BUNDLE_ID=com.social4hyq.chatgpt
APP_MODULE=electron
APP_ABILITY=EntryAbility
HAP=${CHATGPT_APP_UNSIGNED_HAP:?missing unsigned HAP path}
APP_INSTALLER=${CHATGPT_APP_INSTALLER:-app-installer}
HDC=${CHATGPT_APP_HDC:-${CHATGPT_APP_HDC_DEFAULT:-hdc}}
INSTALL_SCRIPT=${CHATGPT_APP_INSTALL_SCRIPT:?missing ChatGPT install script path}

usage() {
  cat <<'EOF'
Usage: codex-app <command>

  install     Inject host Codex paths, sign, and install ChatGPT
  serve       Start the shared codex app-server on 127.0.0.1 if it is not
              running. The app attaches to it, so the app, `codex-app tui`
              and other clients see the same threads. It keeps running after
              the app exits. (When the app is opened first it starts one
              itself, which ends with the app, and this finds it.) Options:
              --port N (default 14288), --stop, --status
  tui         Open the Codex terminal UI on the shared server (extra
              arguments go to codex)
  start       Start the installed ChatGPT app
  stop        Force-stop the app on the selected device
  status      Show whether the app is running on the selected device
  uninstall   Remove ChatGPT from the selected device. The default keeps the
              app's data; --purge also deletes it.

Device options (start/stop/status/uninstall):
  --device ID  hdc target serial (default: HDC_TARGET, else the first
               connected device)
  --purge      uninstall only: delete the app's data

Set HDC_TARGET to select a connected device when more than one is available.
EOF
}

# Shared app-server (runs on the host, no device needed). The app reads
# ~/.config/codex-app/server.json (see owl-share.cjs); the token file next to it
# is the WebSocket capability token.
CODEX_CLI=${CODEX_APP_CODEX_CLI:-${CHATGPT_APP_CODEX_CLI:-codex}}
NODE=${CODEX_APP_NODE:-${CHATGPT_APP_NODE:-node}}
SHARE_DIR=$HOME/.config/codex-app
SHARE_FILE=$SHARE_DIR/server.json
SHARE_TOKEN=$SHARE_DIR/ws-token
SHARE_LOG=$SHARE_DIR/server.log
SHARE_DEFAULT_PORT=14288

share_field() {
  "$NODE" -e 'const d = JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8")); process.stdout.write(String(d[process.argv[2]] ?? ""))' "$SHARE_FILE" "$1" 2>/dev/null || true
}

share_ready() {
  # Asked through Node, which this script needs anyway, so a stand-in curl on PATH cannot answer for it.
  "$NODE" -e 'const request = require("node:http").get({ host: "127.0.0.1", port: Number(process.argv[1]), path: "/readyz", timeout: 2000 }, (response) => { response.resume(); process.exit(response.statusCode === 200 ? 0 : 1); }); request.on("timeout", () => request.destroy()); request.on("error", () => process.exit(1));' "$1" >/dev/null 2>&1
}

share_serve() {
  local port=$SHARE_DEFAULT_PORT action=start
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --port)
        [[ $# -ge 2 && "$2" =~ ^[0-9]+$ ]] || { printf 'codex-app: --port needs a number\n' >&2; exit 2; }
        port="$2"; shift 2 ;;
      --stop) action=stop; shift ;;
      --status) action=status; shift ;;
      *) usage >&2; exit 2 ;;
    esac
  done
  local current="" pid=""
  if [[ -f "$SHARE_FILE" ]]; then
    current="$(share_field port)"
    pid="$(share_field pid)"
  fi
  case "$action" in
    status)
      if [[ -n "$current" ]] && share_ready "$current"; then
        printf 'codex-app: serving at ws://127.0.0.1:%s (pid %s)\n' "$current" "$pid"
      else
        printf 'codex-app: shared server not running; run: codex-app serve\n' >&2
        exit 1
      fi
      ;;
    stop)
      # Only signal a pid that is still an app-server, never a reused one.
      command_line=""
      [[ -z "$pid" ]] || command_line="$(tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null || true)"
      if [[ "$command_line" == *app-server* ]]; then
        kill "$pid" 2>/dev/null || true
        for _ in 1 2 3 4 5 6 7 8 9 10; do
          kill -0 "$pid" 2>/dev/null || break
          sleep 0.5
        done
      fi
      [[ ! -f "$SHARE_FILE" ]] || rm "$SHARE_FILE"
      printf 'codex-app: shared server stopped\n'
      ;;
    start)
      if [[ -n "$current" ]]; then
        if share_ready "$current"; then
          printf 'codex-app: serving at ws://127.0.0.1:%s (pid %s)\n' "$current" "$pid"
          return 0
        fi
        rm "$SHARE_FILE"   # left behind by a server that is gone
      fi
      if share_ready "$port"; then
        printf 'codex-app: port %s already answers; pick another with --port\n' "$port" >&2
        exit 1
      fi
      mkdir -p "$SHARE_DIR"
      if [[ ! -s "$SHARE_TOKEN" ]]; then
        (umask 077; "$NODE" -e 'process.stdout.write(require("node:crypto").randomBytes(24).toString("hex"))' >"$SHARE_TOKEN")
      fi
      chmod 600 "$SHARE_TOKEN"
      # The desktop's own flags (it switches its bundled tools plugin off the same
      # way), so a client that attaches gets the server it would have started.
      nohup "$CODEX_CLI" -c features.code_mode_host=true app-server \
        -c plugins.codex-app-tools@openai-bundled.mcp_servers.codex_app.enabled=false \
        --listen "ws://127.0.0.1:$port" --ws-auth capability-token --ws-token-file "$SHARE_TOKEN" \
        --analytics-default-enabled >>"$SHARE_LOG" 2>&1 </dev/null &
      pid=$!
      for _ in $(seq 1 60); do
        share_ready "$port" && break
        if ! kill -0 "$pid" 2>/dev/null; then
          printf 'codex-app: the server exited at start; see %s\n' "$SHARE_LOG" >&2
          tail -n 5 "$SHARE_LOG" >&2 || true
          exit 1
        fi
        sleep 0.5
      done
      if ! share_ready "$port"; then
        kill "$pid" 2>/dev/null || true
        printf 'codex-app: the server did not become ready; see %s\n' "$SHARE_LOG" >&2
        exit 1
      fi
      "$NODE" -e 'require("node:fs").writeFileSync(process.argv[1], JSON.stringify({ version: 1, port: Number(process.argv[2]), tokenFile: process.argv[3], pid: Number(process.argv[4]), startedAt: new Date().toISOString() }) + "\n")' "$SHARE_FILE" "$port" "$SHARE_TOKEN" "$pid"
      printf 'codex-app: serving at ws://127.0.0.1:%s (pid %s), log %s\n' "$port" "$pid" "$SHARE_LOG"
      ;;
  esac
}

share_tui() {
  local current=""
  [[ ! -f "$SHARE_FILE" ]] || current="$(share_field port)"
  if [[ -z "$current" ]] || ! share_ready "$current"; then
    printf 'codex-app: shared server not running; run: codex-app serve\n' >&2
    exit 1
  fi
  CODEX_APP_WS_TOKEN="$(cat "$SHARE_TOKEN")" exec "$CODEX_CLI" \
    --remote "ws://127.0.0.1:$current" --remote-auth-token-env CODEX_APP_WS_TOKEN "$@"
}

case ${1:-} in
  install)
    shift
    exec "$INSTALL_SCRIPT" "$@"
    ;;
  serve)
    shift
    share_serve "$@"
    ;;
  tui)
    shift
    share_tui "$@"
    ;;
  start|stop|status|uninstall)
    command="${1}"
    shift
    device="${HDC_TARGET:-}"
    purge=0
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --device)
          [[ $# -ge 2 && -n "$2" ]] || { printf 'codex-app: --device needs an id\n' >&2; exit 2; }
          device="$2"; shift 2 ;;
        --purge)
          [[ "$command" == uninstall ]] || { printf 'codex-app: --purge is only valid for uninstall\n' >&2; exit 2; }
          purge=1; shift ;;
        *) usage >&2; exit 2 ;;
      esac
    done
    [[ -x "$HDC" ]] || command -v "$HDC" >/dev/null
    hdc_args=()
    [[ -z "$device" ]] || hdc_args+=(-t "$device")
    case "$command" in
      start)
        "$HDC" "${hdc_args[@]}" shell aa start -a "$APP_ABILITY" -b "$APP_BUNDLE_ID" -m "$APP_MODULE"
        ;;
      stop)
        "$HDC" "${hdc_args[@]}" shell aa force-stop "$APP_BUNDLE_ID"
        printf 'codex-app: stopped %s\n' "$APP_BUNDLE_ID"
        ;;
      status)
        # Match only app command names; unrelated shell arguments may mention the bundle.
        processes="$("$HDC" "${hdc_args[@]}" shell "ps -ef" 2>/dev/null || true)"
        if printf '%s\n' "$processes" | awk -v bundle="$APP_BUNDLE_ID" '
          $8 == bundle || index($8, bundle ":") == 1 { found = 1 }
          END { exit !found }
        '; then
          printf 'codex-app: running (%s)\n' "$APP_BUNDLE_ID"
        else
          printf 'codex-app: not running (%s)\n' "$APP_BUNDLE_ID" >&2
          exit 1
        fi
        ;;
      uninstall)
        # app-installer runs 'bm uninstall -k' unless --purge is given, so the
        # app's data survives a plain uninstall.
        args=(uninstall --bundle-id "$APP_BUNDLE_ID")
        [[ -z "$device" ]] || args+=(--device "$device")
        [[ "$purge" == 0 ]] || args+=(--purge)
        "$APP_INSTALLER" "${args[@]}"
        ;;
    esac
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
