#!/usr/bin/env bash
# herdr-app: sign and install the Herdr desktop HAP, run the core bridge it talks to, and open it.
set -euo pipefail

BUNDLE_ID="com.social4hyq.herdrapp"
ABILITY="EntryAbility"
DEFAULT_PORT="${HERDR_APP_PORT:-8765}"
# State lives under the real home, like every other *-app. brew's post_install run gets
# a throw-away XDG_CONFIG_HOME: a state dir taken from it holds a bridge nobody can find
# again (no pidfile in the dir the user's shell looks at), which then keeps the port busy.
STATE="${HERDR_APP_STATE:-$HOME/.config/herdr-app}"
CONF="$STATE/bridge.conf"
PIDFILE="$STATE/bridge.pid"
LOGFILE="$STATE/bridge.log"

# Earlier versions kept the state under $XDG_CONFIG_HOME. Adopt its bridge.conf once so an
# app installed earlier keeps its token.
legacy_conf="${XDG_CONFIG_HOME:+$XDG_CONFIG_HOME/herdr-app/bridge.conf}"
if [[ -z "${HERDR_APP_STATE:-}" && -n "$legacy_conf" && "$legacy_conf" != "$CONF" &&
      ! -f "$CONF" && -f "$legacy_conf" ]]; then
  mkdir -p "$STATE" && chmod 700 "$STATE" 2>/dev/null || true
  cp "$legacy_conf" "$CONF" && chmod 600 "$CONF" 2>/dev/null || true
fi

usage() {
  cat <<'EOF'
Usage: herdr-app <command> [options]

Commands:
  install [--device <hdc serial>] [--new-token]
            Make sure the core bridge and its token exist and the bridge is running, put the
            bridge's address and token into the HAP, sign it with a local debug profile, install
            it over hdc and open it (needs hdc and an unlocked device). --new-token replaces the
            token, so an app installed earlier stops being accepted until it is installed again.
  start [--device <hdc serial>]
            Make sure the bridge is running, then open the installed app
  stop      Stop the core bridge (the app window stays open)
  status    Print the bridge state; exit 1 when it is stopped
  uninstall [--device <hdc serial>] [--purge]
            Remove the app from the device. The default keeps the app's data;
            --purge also deletes it.
  bridge start|stop|restart|status
            Run the core bridge by itself. It listens on 127.0.0.1 only and answers only the
            app that carries the token.
  -h, --help  Show this help
EOF
}

die() {
  printf 'herdr-app: %s\n' "$1" >&2
  exit "${2:-1}"
}

port_busy() {
  (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null && { exec 3>&- 3<&-; return 0; } || return 1
}

conf_value() { # conf_value <key>
  sed -n "s/^$1=//p" "$CONF" 2>/dev/null | tail -n 1
}

conf_ok() {
  [[ -f "$CONF" && "$(conf_value addr)" == 127.0.0.1:* && "$(conf_value token)" =~ ^[0-9a-f]{32,}$ ]]
}

# Write bridge.conf: the address the bridge listens on and the token the app must show.
make_conf() { # make_conf <keep the port 1|0>
  mkdir -p "$STATE"
  chmod 700 "$STATE" 2>/dev/null || true
  local port
  if [[ "$1" == 1 ]] && conf_ok; then
    port="$(conf_value addr)"; port="${port##*:}"
  else
    port="$DEFAULT_PORT"
    local tries=0
    while port_busy "$port"; do
      port=$((port + 1))
      tries=$((tries + 1))
      ((tries < 30)) || die "no free loopback port near $DEFAULT_PORT"
    done
  fi
  local token tmp
  token="$(head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')"
  tmp="$STATE/.bridge.conf.$$"
  (umask 077; printf 'addr=127.0.0.1:%s\ntoken=%s\n' "$port" "$token" > "$tmp")
  mv -f "$tmp" "$CONF"
  chmod 600 "$CONF" 2>/dev/null || true
}

ensure_conf() {
  conf_ok || make_conf 0
}

bridge_pid() { # prints the pid of our running bridge, or nothing
  [[ -f "$PIDFILE" ]] || return 0
  local pid; pid="$(cat "$PIDFILE" 2>/dev/null || true)"
  if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null && ps -p "$pid" -o args= 2>/dev/null | grep -q 'herdr-bridge'; then
    printf '%s\n' "$pid"
  fi
}

bridge_check() {
  "${HERDR_APP_PYTHON:-python3}" "${HERDR_APP_BRIDGE:?formula did not set the bridge path}" --check --config "$CONF" 2>/dev/null
}

# The core binds its socket under $TMPDIR: on OHOS the user-storage mount
# holding $HOME refuses socket nodes. A TMPDIR on that mount (a configured
# ~/tmp, for example) therefore breaks hc even though ordinary files work.
# Probe a real UNIX socket and fall back to the terminal app's data directory.
ensure_socket_tmpdir() {
  local candidate
  for candidate in "${TMPDIR:-}" "${XDG_CACHE_HOME:-$HOME/.cache}" "$HOME/.cache" "/data/storage/el2/base/cache" "/data/storage/el2/base/files" "/tmp"; do
    [ -n "$candidate" ] || continue
    mkdir -p "$candidate" 2>/dev/null || continue
    if "${HERDR_APP_PYTHON:-python3}" - "$candidate" 2>/dev/null <<'PY'
import os, socket, sys
path = os.path.join(sys.argv[1], f".herdr-socket-{os.getpid()}")
sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
try:
    sock.bind(path)
finally:
    sock.close()
    try:
        os.unlink(path)
    except OSError:
        pass
PY
    then
      export TMPDIR="$candidate"
      return 0
    fi
  done
  return 1
}

bridge_start() {
  ensure_conf
  if [[ -z "$(bridge_pid)" ]] && bridge_check; then
    printf 'herdr-app: using the externally managed bridge at %s\n' "$(conf_value addr)" >&2
    return 0
  fi
  ensure_socket_tmpdir ||
    die "no directory that can hold a UNIX socket; set TMPDIR to the terminal app's cache (for example /data/storage/el2/base/cache)"
  if [[ -n "$(bridge_pid)" ]]; then
    local recorded
    recorded="$(cat "$STATE/bridge.tmpdir" 2>/dev/null || true)"
    if [[ "$recorded" == "$TMPDIR" ]]; then
      bridge_check || die "the bridge is running (pid $(bridge_pid)) but does not accept this token; run: herdr-app bridge restart"
      return 0
    fi
    # Started under a different TMPDIR (typically the broken one an older
    # install picked up): restart it so hc binds under the socket-capable one.
    bridge_stop
  fi
  local hc="${HERDR_APP_HC:-hc}"
  : > "$LOGFILE"
  chmod 600 "$LOGFILE" 2>/dev/null || true
  printf '%s\n' "$TMPDIR" > "$STATE/bridge.tmpdir" 2>/dev/null || true
  chmod 600 "$STATE/bridge.tmpdir" 2>/dev/null || true
  # Its own session when setsid exists, so closing the terminal that ran this does not end the bridge.
  local detach=(nohup)
  command -v setsid >/dev/null 2>&1 && detach=(setsid nohup)
  HC_BIN="$hc" "${detach[@]}" "${HERDR_APP_PYTHON:-python3}" "${HERDR_APP_BRIDGE:?formula did not set the bridge path}" --config "$CONF" >> "$LOGFILE" 2>&1 < /dev/null &
  local started=$!
  printf '%s\n' "$started" > "$PIDFILE"
  local i
  for i in $(seq 1 50); do
    if bridge_check; then
      printf 'herdr-app: bridge listening on %s\n' "$(conf_value addr)" >&2
      return 0
    fi
    kill -0 "$started" 2>/dev/null || break
    sleep 0.1
  done
  rm -f "$PIDFILE"
  die "the bridge did not start ($(tail -n 3 "$LOGFILE" 2>/dev/null | tr '\n' ' ')); is something else using $(conf_value addr)?"
}

bridge_stop() {
  local pid; pid="$(bridge_pid)"
  if [[ -z "$pid" ]]; then
    if conf_ok && bridge_check; then
      die 'the bridge is managed externally; if using Harbor, run: harbor stop herdr-app'
    fi
    rm -f "$PIDFILE"
    printf 'herdr-app: the bridge is not running\n' >&2
    return 0
  fi
  kill "$pid" 2>/dev/null || true
  local i
  for i in $(seq 1 30); do kill -0 "$pid" 2>/dev/null || break; sleep 0.1; done
  if kill -0 "$pid" 2>/dev/null; then kill -9 "$pid" 2>/dev/null || true; fi
  rm -f "$PIDFILE"
  printf 'herdr-app: the bridge is stopped\n' >&2
}

bridge_status() {
  if ! conf_ok; then
    printf 'bridge: not set up (no usable %s); run `herdr-app install`\n' "$CONF"
    return 1
  fi
  printf 'bridge address: %s\n' "$(conf_value addr)"
  printf 'config:         %s\n' "$CONF"
  local pid; pid="$(bridge_pid)"
  if [[ -z "$pid" ]]; then
    if bridge_check; then
      printf 'bridge:         running (externally managed)\ntoken:          accepted\n'
      return 0
    fi
    printf 'bridge:         not running\n'
    return 1
  fi
  printf 'bridge:         running (pid %s)\n' "$pid"
  if bridge_check; then
    printf 'token:          accepted\n'
  else
    printf 'token:          NOT accepted by the running bridge; run `herdr-app bridge restart`\n'
    return 1
  fi
}

# mktemp -d creates a 0700 directory. On hmdfs a new directory inherits its
# parent's owner, so when TMPDIR points at a directory owned by another uid (a
# configured ~/tmp, for example) the stage belongs to that owner and the desktop
# user cannot write the HAP into it. Probe each candidate and use the first one
# this process can actually write.
make_stage() {
  local root stage
  for root in "${TMPDIR:-}" "${XDG_CACHE_HOME:-$HOME/.cache}" "$HOME/.cache" "$STATE/tmp"; do
    [ -n "$root" ] || continue
    mkdir -p "$root" 2>/dev/null || continue
    stage="$(umask 077; mktemp -d "$root/herdr-app-inject.XXXXXX" 2>/dev/null)" || continue
    if (umask 077; : > "$stage/.write-test") 2>/dev/null; then
      rm -f "$stage/.write-test" 2>/dev/null || true
      printf '%s' "$stage"
      return 0
    fi
    rm -rf "$stage" 2>/dev/null || true
  done
  return 1
}

# Copy the HAP and add the bridge's address and token as rawfile/bridge.conf; the app reads it at start-up.
inject_conf() { # inject_conf <unsigned hap> <output hap>
  "${HERDR_APP_PYTHON:-python3}" - "$1" "$2" "$CONF" <<'PY'
import shutil, sys, zipfile
src, dst, conf = sys.argv[1:4]
values = {}
with open(conf) as handle:
    for line in handle:
        key, _, value = line.strip().partition("=")
        if key in ("addr", "token"):
            values[key] = value
if not values.get("addr", "").startswith("127.0.0.1:") or len(values.get("token", "")) < 32:
    sys.exit("herdr-app: bridge.conf is incomplete")
shutil.copyfile(src, dst)
name = "resources/rawfile/bridge.conf"
with zipfile.ZipFile(dst, "a") as hap:
    if name in hap.namelist():
        sys.exit("herdr-app: the HAP already carries a bridge.conf")
    info = zipfile.ZipInfo(name, date_time=(2020, 1, 1, 0, 0, 0))
    info.compress_type = zipfile.ZIP_STORED
    hap.writestr(info, f"addr={values['addr']}\ntoken={values['token']}\n")
PY
}

command_name="${1:-}"
case "$command_name" in
  -h|--help|help|"") usage; [[ -n "$command_name" ]] || exit 2; exit 0 ;;
  install|start|stop|status|uninstall|bridge) shift ;;
  *) usage >&2; exit 2 ;;
esac

if [[ "$command_name" == bridge ]]; then
  action="${1:-}"
  (($# <= 1)) || { usage >&2; exit 2; }
  case "$action" in
    start) bridge_start ;;
    stop) bridge_stop ;;
    restart) bridge_stop; bridge_start ;;
    status) bridge_status ;;
    *) usage >&2; exit 2 ;;
  esac
  exit
fi

device=
new_token=0
purge=0
while (($#)); do
  case "$1" in
    --device)
      (($# >= 2)) && [[ -n "$2" && "$2" != --* ]] || die "missing value for --device" 2
      device="$2"
      shift 2 ;;
    --new-token)
      [[ "$command_name" == install ]] || { usage >&2; exit 2; }
      new_token=1
      shift ;;
    --purge)
      [[ "$command_name" == uninstall ]] || { usage >&2; exit 2; }
      purge=1
      shift ;;
    *) usage >&2; exit 2 ;;
  esac
done

hdc="${HERDR_APP_HDC:-${HERDR_APP_HDC_DEFAULT:-hdc}}"
hdc_args=()
[[ -z "$device" ]] || hdc_args=(-t "$device")

case "$command_name" in
  install)
    hap="${HERDR_APP_HAP:?formula did not set the HAP path}"
    [[ -f "$hap" ]] || die "HAP not found: $hap"
    command -v app-installer >/dev/null || die "command not found: app-installer"
    if ((new_token)); then
      bridge_stop
      make_conf 1
    fi
    bridge_start
    stage="$(make_stage)" || die "no writable staging directory; set TMPDIR to a directory this user can write (current TMPDIR=${TMPDIR:-unset})"
    trap 'rm -rf "$stage"' EXIT
    # Child tools (app-installer, python, split) use TMPDIR too; keep them inside
    # the stage that was just proven writable.
    export TMPDIR="$stage"
    inject_conf "$hap" "$stage/herdr-app.hap"
    install_args=(--hap "$stage/herdr-app.hap" --signed-hap "$stage/signed.hap" --bundle-id "$BUNDLE_ID" --app-name Herdr --module entry --ability "$ABILITY" --hdc "$hdc")
    [[ -z "$device" ]] || install_args+=(--device "$device")
    app-installer "${install_args[@]}"
    printf 'herdr-app: installed with a bridge token; the token is in %s (mode 600) and inside the app\n' "$CONF" >&2
    ;;
  start)
    conf_ok || die "no bridge set up yet; run: herdr-app install"
    bridge_start
    "$hdc" ${hdc_args[@]+"${hdc_args[@]}"} shell aa start -b "$BUNDLE_ID" -a "$ABILITY"
    ;;
  stop)
    bridge_stop
    ;;
  status)
    bridge_status
    ;;
  uninstall)
    # app-installer runs 'bm uninstall -k' unless --purge is given, so the
    # app's data survives a plain uninstall.
    device="${device:-${HDC_TARGET:-}}"
    install_args=(uninstall --bundle-id "$BUNDLE_ID")
    [[ -z "$device" ]] || install_args+=(--device "$device")
    ((purge)) && install_args+=(--purge)
    "${APP_INSTALLER:-app-installer}" "${install_args[@]}"
    ;;
esac
