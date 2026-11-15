#!/bin/sh
# deepseek-harness-desktop: manage the host-side runtime bridge and the HAP.
#
#   deepseek-harness-desktop install             sign + install + launch the HAP
#   deepseek-harness-desktop start [--bridge-only]
#   deepseek-harness-desktop stop
#   deepseek-harness-desktop status
set -eu

STATE_DIR="${DSH_BRIDGE_STATE_DIR:-$HOME/.deepseek-harness-desktop}"
PID_FILE="$STATE_DIR/bridge.pid"
LOG_FILE="$STATE_DIR/bridge.log"
BRIDGE="${DSH_DESKTOP_BRIDGE_JS:?DSH_DESKTOP_BRIDGE_JS is required}"
NODE_BIN="${DSH_BRIDGE_NODE:?DSH_BRIDGE_NODE is required}"
RUNTIME_DIR="${DSH_DESKTOP_RUNTIME_DIR:?DSH_DESKTOP_RUNTIME_DIR is required}"
HAP="${DSH_DESKTOP_UNSIGNED_HAP:?DSH_DESKTOP_UNSIGNED_HAP is required}"
INSTALLER="${DSH_DESKTOP_INSTALLER:-hap-installer}"

mkdir -p "$STATE_DIR"

pid() { [ -f "$PID_FILE" ] && cat "$PID_FILE" 2>/dev/null || true; }
alive() { p=$(pid); [ -n "$p" ] && kill -0 "$p" 2>/dev/null; }
# 运行中进程的命令行是否仍指向当前安装（brew upgrade 后旧 bridge 会指向已删除的 keg）。
current() {
  alive || return 1
  p=$(pid)
  cmd=$(tr '\0' ' ' < "/proc/$p/cmdline" 2>/dev/null || true)
  [ -n "$cmd" ] || return 0
  case "$cmd" in
    *"$BRIDGE"*) return 0 ;;
    *) return 1 ;;
  esac
}

start() {
  if current; then
    echo "bridge already running (pid $(pid))"
    return 0
  fi
  if alive; then
    echo "replacing stale bridge (pid $(pid))"
    kill "$(pid)" 2>/dev/null || true
    sleep 1
  fi
  DSH_BRIDGE_NODE="$NODE_BIN" setsid nohup "$NODE_BIN" "$BRIDGE" >> "$LOG_FILE" 2>&1 < /dev/null &
  sleep 1
  if alive; then
    echo "bridge started (pid $(pid)), log $LOG_FILE"
  else
    echo "bridge failed to start; see $LOG_FILE" >&2
    return 1
  fi
}

stop() {
  if alive; then
    kill "$(pid)" 2>/dev/null || true
    echo "bridge stopped"
  else
    echo "bridge not running"
  fi
}

status() {
  if current; then
    echo "bridge: running (pid $(pid))"
  elif alive; then
    echo "bridge: running a stale version (pid $(pid)); run start to replace it"
  else
    echo "bridge: not running"
  fi
  version=$(python3 -c "import json;print(json.load(open('$RUNTIME_DIR/desktop-runtime.json'))['release']['version'])" 2>/dev/null \
    || sed -n 's/.*"version": "\(.*\)".*/\1/p' "$RUNTIME_DIR/desktop-runtime.json" 2>/dev/null | head -1)
  echo "runtime: ${version:-unknown}"
  if [ -f "$HAP" ]; then
    echo "hap: $HAP"
  else
    echo "hap: missing"
  fi
}

install_hap() {
  # Signing material stays in the user's home; hap-installer creates the
  # signing project on first use.
  exec "$INSTALLER" --hap "$HAP" \
    --bundle-id com.social4hyq.deepseekharness \
    --app-name DeepSeekHarnessSigning \
    --module electron \
    --ability EntryAbility
}

case "${1:-}" in
  install) shift; install_hap "$@" ;;
  start) shift; start "$@" ;;
  stop) shift; stop ;;
  status) shift; status ;;
  *)
    echo "usage: deepseek-harness-desktop {install|start [--bridge-only]|stop|status}" >&2
    exit 2
    ;;
esac
