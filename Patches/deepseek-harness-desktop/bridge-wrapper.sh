#!/bin/sh
# Launch (or report) the host-side dsh desktop bridge. Idempotent.
#   dsh-desktop-bridge         ensure running (detached), print status
#   dsh-desktop-bridge stop    stop a running bridge
set -eu

STATE_DIR="${DSH_BRIDGE_STATE_DIR:-$HOME/.deepseek-harness-desktop}"
PID_FILE="$STATE_DIR/bridge.pid"
LOG_FILE="$STATE_DIR/bridge.log"
BRIDGE="${DSH_DESKTOP_BRIDGE_JS:?DSH_DESKTOP_BRIDGE_JS is required}"
NODE_BIN="${DSH_BRIDGE_NODE:?DSH_BRIDGE_NODE is required}"

mkdir -p "$STATE_DIR"

running() {
  [ -f "$PID_FILE" ] || return 1
  pid=$(cat "$PID_FILE" 2>/dev/null || true)
  [ -n "$pid" ] || return 1
  kill -0 "$pid" 2>/dev/null
}

case "${1:-}" in
  stop)
    if running; then
      kill "$(cat "$PID_FILE")" && echo "bridge stopped"
    else
      echo "bridge not running"
    fi
    exit 0
    ;;
  ""|start)
    if running; then
      echo "bridge already running (pid $(cat "$PID_FILE"))"
      exit 0
    fi
    DSH_BRIDGE_NODE="$NODE_BIN" setsid nohup "$NODE_BIN" "$BRIDGE" >> "$LOG_FILE" 2>&1 < /dev/null &
    sleep 1
    if running; then
      echo "bridge started (pid $(cat "$PID_FILE"))"
    else
      echo "bridge failed to start; see $LOG_FILE" >&2
      exit 1
    fi
    ;;
  *)
    echo "usage: dsh-desktop-bridge [start|stop]" >&2
    exit 2
    ;;
esac
