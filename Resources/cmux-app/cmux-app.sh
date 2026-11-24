#!/usr/bin/env bash
# cmux-app: inject the host herdr-bridge address+token into the HAP as
# resources/rawfile/bridge.conf, sign+install over hdc, and keep the bridge up.
# Mirrors herdr-app.sh (tap Resources/herdr-app/scripts/herdr-app.sh).
set -euo pipefail

BUNDLE_ID="com.social4hyq.cmuxapp"
ABILITY="EntryAbility"
STATE="${CMUX_APP_STATE:-$HOME/.config/cmux-app}"
CONF="$STATE/bridge.conf"
PIDFILE="$STATE/bridge.pid"
LOGFILE="$STATE/bridge.log"
HAP="${CMUX_APP_HAP:?CMUX_APP_HAP not set}"
HC="${CMUX_APP_HC:-hc}"
BRIDGE="${CMUX_APP_BRIDGE:?CMUX_APP_BRIDGE not set}"
PYTHON="${CMUX_APP_PYTHON:-python3}"
APP_INSTALLER="${APP_INSTALLER:-app-installer}"
HDC="${CMUX_APP_HDC:-hdc}"

die() { printf 'cmux-app: %s\n' "$1" >&2; exit "${2:-1}"; }

make_conf() {
  mkdir -p "$STATE"; chmod 700 "$STATE" 2>/dev/null || true
  local port="$1" token tmp
  token="$(head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')"
  tmp="$STATE/.bridge.conf.$$"
  (umask 077; printf 'addr=127.0.0.1:%s\ntoken=%s\n' "$port" "$token" > "$tmp")
  mv -f "$tmp" "$CONF"; chmod 600 "$CONF" 2>/dev/null || true
}

port_busy() { (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null && { exec 3>&- 3<&-; return 0; } || return 1; }

ensure_conf() {
  if [[ -f "$CONF" ]]; then
    local addr; addr="$(sed -n 's/^addr=//p' "$CONF" | tail -1)"
    local tok; tok="$(sed -n 's/^token=//p' "$CONF" | tail -1)"
    [[ "$addr" == 127.0.0.1:* && "$tok" =~ ^[0-9a-f]{32,}$ ]] && return 0
  fi
  local port="${CMUX_APP_PORT:-8765}" tries=0
  while port_busy "$port"; do port=$((port + 1)); tries=$((tries+1)); ((tries<30)) || die "no free port"; done
  make_conf "$port"
}

bridge_pid() {
  [[ -f "$PIDFILE" ]] || return 0
  local pid; pid="$(cat "$PIDFILE" 2>/dev/null || true)"
  [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null && printf '%s\n' "$pid"
}

bridge_start() {
  ensure_conf
  [[ -n "$(bridge_pid)" ]] && return 0
  : > "$LOGFILE"; chmod 600 "$LOGFILE" 2>/dev/null || true
  HC_BIN="$HC" nohup "$PYTHON" "$BRIDGE" --config "$CONF" >> "$LOGFILE" 2>&1 < /dev/null &
  echo $! > "$PIDFILE"
  local i
  for i in $(seq 1 50); do
    "$PYTHON" "$BRIDGE" --check --config "$CONF" 2>/dev/null && return 0
    sleep 0.1
  done
  die "bridge did not start: $(tail -3 "$LOGFILE" | tr '\n' ' ')"
}

inject_conf() {
  "$PYTHON" - "$1" "$2" "$CONF" <<'PY'
import shutil, sys, zipfile
src, dst, conf = sys.argv[1:4]
v={}
for line in open(conf):
    k,_,val=line.strip().partition('=')
    if k in ('addr','token'): v[k]=val
assert v.get('addr','').startswith('127.0.0.1:') and len(v.get('token',''))>=32
shutil.copyfile(src,dst)
with zipfile.ZipFile(dst,'a') as h:
    name="resources/rawfile/bridge.conf"
    assert name not in h.namelist(), "bridge.conf already in HAP"
    zi=zipfile.ZipInfo(name,date_time=(2020,1,1,0,0,0)); zi.compress_type=zipfile.ZIP_STORED
    h.writestr(zi, f"addr={v['addr']}\ntoken={v['token']}\n")
PY
}

case "${1:-install}" in
  install)
    [[ -f "$HAP" ]] || die "HAP not found: $HAP"
    bridge_start
    stage="$(umask 077; mktemp -d "${TMPDIR:-/data/storage/el2/base/cache}/cmux-app-inject.XXXXXX")" || die "no staging dir"
    trap 'rm -rf "$stage"' EXIT
    inject_conf "$HAP" "$stage/cmux-app.hap"
    "$APP_INSTALLER" install --hap "$stage/cmux-app.hap" \
      --bundle-id "$BUNDLE_ID" --app-name cmux_app --module entry --ability "$ABILITY" \
      --hdc "$HDC" --no-browser
    ;;
  start)
    bridge_start
    "$HDC" shell aa start -b "$BUNDLE_ID" -a "$ABILITY" ;;
  stop)
    pid="$(bridge_pid)"; [[ -n "$pid" ]] && kill "$pid" 2>/dev/null || true; rm -f "$PIDFILE" ;;
  *) die "usage: cmux-app install|start|stop" ;;
esac
