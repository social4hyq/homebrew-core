#!/usr/bin/env bash
# Install this tap's HAP apps on the connected device after `brew install` or
# `brew upgrade` has already done its part. The formula's post_install_steps
# call `hap-app auto-install <command> <bundle>`; when the device or the Huawei
# Developer login is missing, the app is queued instead and
# `hap-app install-pending` finishes it later.
#
# The auto path never starts the app, never fails the brew install and never
# waits for a login unless HAP_APP_AUTO_LOGIN=1. Configuration lives in
# $XDG_CONFIG_HOME/hap-app/config (`auto_install=0`, `auto_login=1`).

set -uo pipefail

app_installer="${HAP_APP_APP_INSTALLER:-app-installer}"
node_bin="${HAP_APP_NODE:-node}"

# Homebrew runs post_install with a throwaway HOME, a cleared environment and no
# readable /proc/PID/environ, so hdc (keys under ~/.harmony), devecocli (login
# state under ~) and app-installer (signing projects under ~/.hap-installer)
# cannot see the user's session. This tap installs into ~/.harmonybrew, so the
# prefix's parent is the real home; HAP_APP_USER_HOME overrides it and it is
# only trusted when it really looks like a home directory.
recover_user_home() {
  local candidate=""
  if [ -n "${HAP_APP_USER_HOME:-}" ]; then
    candidate="$HAP_APP_USER_HOME"
  elif [ -n "${HOMEBREW_PREFIX:-}" ]; then
    candidate="$(dirname "$HOMEBREW_PREFIX")"
  fi
  if [ -n "$candidate" ] && [ -d "$candidate" ] && {
    [ -e "$candidate/.HDCServer.pid" ] || [ -d "$candidate/.harmony" ] ||
      [ -d "$candidate/.hap-installer" ] || [ -d "$candidate/.app-installer" ]
  }; then
    export HOME="$candidate"
  fi
}
recover_user_home

# State lives under the (recovered) home so the post_install run and the user's
# own shells agree, even when XDG_CONFIG_HOME/XDG_CACHE_HOME point elsewhere.
config_dir="${HAP_APP_CONFIG_DIR:-$HOME/.config/hap-app}"
cache_dir="${HAP_APP_CACHE_DIR:-$HOME/.cache/hap-app}"
queue_dir="$cache_dir/pending"

log() { printf 'hap-app: %s\n' "$*" >&2; }
say() { printf 'hap-app: %s\n' "$*"; }
die() { log "$*"; exit 1; }

usage() {
  cat <<'EOF'
Usage: hap-app <command> [options]

  auto-install <app-command> <bundle-id> [--start] [--device <id>]
                Install one app's HAP now, or queue it when the device or the
                Huawei Developer login is not ready. Called by the formula's
                post_install_steps; exits 0 even when it only queued the app.
  install-pending [--start] [--device <id>]
                Install every queued app, logging in once if needed.
  status        Show the queued apps.
  forget <app-command>
                Remove one app from the queue.
  help          Show this help.

Environment:
  HAP_APP_AUTO_INSTALL=0   Do not install or queue automatically (config file:
                           ~/.config/hap-app/config, auto_install=0)
  HAP_APP_AUTO_LOGIN=1     Let auto-install open the Huawei Developer login
                           and wait up to HAP_APP_LOGIN_TIMEOUT seconds (120)
                           (config file: auto_login=1)
  HAP_APP_INSTALL_TIMEOUT  Overall install timeout in seconds (900)
  HAP_APP_USER_HOME        Override the home directory recovered from
                           HOMEBREW_PREFIX (for tests or unusual layouts)
EOF
}

conf_get() {
  local file="$config_dir/config"
  [ -f "$file" ] || return 0
  sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//p" "$file" | tail -n 1
}

auto_install_setting() {
  local value="${HAP_APP_AUTO_INSTALL:-$(conf_get auto_install)}"
  printf '%s' "${value:-1}"
}

auto_login_setting() {
  local value="${HAP_APP_AUTO_LOGIN:-$(conf_get auto_login)}"
  printf '%s' "${value:-0}"
}

enabled() {
  case "${1:-}" in
    ""|0|no|false|off) return 1 ;;
    *) return 0 ;;
  esac
}

valid_command() {
  [[ "${1:-}" =~ ^[a-z][a-z0-9-]*-app$ ]]
}

valid_bundle() {
  [[ "${1:-}" =~ ^[A-Za-z][A-Za-z0-9_.]*$ ]]
}

queue_file() {
  printf '%s/%s.json' "$queue_dir" "$1"
}

queue_add() {
  local command="$1" bundle="$2" reason="$3"
  valid_command "$command" || { log "invalid app command: $command"; return 1; }
  valid_bundle "$bundle" || { log "invalid bundle id: $bundle"; return 1; }
  mkdir -p "$queue_dir" || { log "cannot create $queue_dir"; return 1; }
  chmod 700 "$config_dir" "$queue_dir" 2>/dev/null || true
  "$node_bin" -e '
const fs = require("node:fs");
const [file, command, bundle, reason] = process.argv.slice(1);
const value = { command, bundle, reason, updated: new Date().toISOString() };
const temporary = `${file}.${process.pid}.tmp`;
fs.writeFileSync(temporary, JSON.stringify(value) + "\n", { mode: 0o600 });
fs.chmodSync(temporary, 0o600);
fs.renameSync(temporary, file);
' "$(queue_file "$command")" "$command" "$bundle" "$reason" ||
    { log "cannot write the pending queue"; return 1; }
}

queue_remove() {
  rm -f -- "$(queue_file "$1")"
}

queue_field() {
  "$node_bin" -e '
const fs = require("node:fs");
const value = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
process.stdout.write(String(value[process.argv[2]] ?? ""));
' "$1" "$2" 2>/dev/null
}

queue_names() {
  local file
  for file in "$queue_dir"/*.json; do
    [ -f "$file" ] || continue
    file="${file##*/}"
    printf '%s\n' "${file%.json}"
  done
}

# The wrapper brew generates for each app exports <PREFIX>_MODULE_ACL; reading
# it from there keeps the queue free of versioned keg paths.
acl_file_for() {
  local wrapper
  wrapper="$(command -v "$1" 2>/dev/null)" || return 0
  [ -f "$wrapper" ] || return 0
  sed -n 's/^.*_MODULE_ACL="\([^"]*\)".*$/\1/p' "$wrapper" | head -n 1
}

probe_ready() {
  local -a args=()
  [ -n "${device_arg:-}" ] && args+=(--device "$device_arg")
  local out
  out="$("$app_installer" ready "${args[@]}" 2>/dev/null)" || true
  printf '%s' "${out%%$'\n'*}"
}

login_recently_attempted() {
  local marker="$cache_dir/login-attempt" last now
  [ -f "$marker" ] || return 1
  last="$(cat "$marker" 2>/dev/null || printf 0)"
  now="$(date +%s)"
  [[ "$last" =~ ^[0-9]+$ ]] && ((now - last < 600))
}

mark_login_attempt() {
  mkdir -p "$cache_dir" && date +%s >"$cache_dir/login-attempt" 2>/dev/null || true
}

# Run "<command> install" for one app, verify the permissions it asked for, and
# queue it when anything failed. Expects the environment to be ready.
install_one() {
  local command="$1" bundle="$2" start="$3" device="${4:-}"
  local acl_file
  acl_file="$(acl_file_for "$command")"

  local -a env_args=(HAP_INSTALLER_NO_LOGIN=1)
  ((start)) || env_args+=(HAP_INSTALLER_NO_START=1)
  [ -n "$device" ] && env_args+=(HAP_INSTALLER_DEVICE="$device")
  local -a timeout_args=()
  command -v timeout >/dev/null 2>&1 &&
    timeout_args=(timeout "${HAP_APP_INSTALL_TIMEOUT:-900}")
  # A few installers open the app themselves; the automatic path must not.
  local -a app_args=()
  case "$command" in
    orca-app) app_args+=(--no-serve) ;;
  esac

  log "installing $bundle"
  local rc=0
  env "${env_args[@]}" "${timeout_args[@]}" "$command" install "${app_args[@]+"${app_args[@]}"}" || rc=$?
  if ((rc != 0)); then
    local reason=install-failed
    [ "$(probe_ready)" = "no-login" ] && reason=login
    queue_add "$command" "$bundle" "$reason"
    say "$command: 装机失败（$reason），已登记待装；运行 hap-app install-pending 重试"
    return 0
  fi

  local -a perms_args=(permissions --bundle-id "$bundle")
  [ -n "$acl_file" ] && perms_args+=(--expect-acl "$acl_file")
  local perms_rc=0 perms_out
  perms_out="$("$app_installer" "${perms_args[@]}" 2>&1)" || perms_rc=$?
  if ((perms_rc != 0)); then
    printf '%s\n' "$perms_out" >&2
    queue_add "$command" "$bundle" permissions
    say "$command: 已装但权限校验未通过，已登记待装；运行 hap-app status 查看"
    return 0
  fi

  queue_remove "$command"
  say "$command: 已装机 $bundle${device:+（设备 $device）}"
  if ((start)); then
    "$command" start >/dev/null 2>&1 || log "$command: 启动失败；稍后手动运行 $command start"
  fi
  return 0
}

auto_install_guarded() {
  local command="$1"
  if ! enabled "$(auto_install_setting)"; then
    log "自动装机已关闭（HAP_APP_AUTO_INSTALL=0）"
    return 1
  fi
  # CI pours bottles and runs regression installs; never touch a device there.
  if [ -n "${CI:-}${GITHUB_ACTIONS:-}${HOMEBREW_GITHUB_ACTIONS:-}" ]; then
    return 1
  fi
  # root installs the kegs (CI containers and brew install run as root there);
  # HAP installs belong to the desktop user. HAP_APP_ALLOW_ROOT exists for the
  # test harness only.
  if [ "$(id -u 2>/dev/null || printf 0)" = "0" ] && [ "${HAP_APP_ALLOW_ROOT:-0}" = "0" ]; then
    log "以 root 运行，跳过自动装机"
    return 1
  fi
  command -v "$app_installer" >/dev/null 2>&1 || { log "找不到 $app_installer"; return 1; }
  command -v "$command" >/dev/null 2>&1 || { log "找不到命令 $command"; return 1; }
  return 0
}

cmd_auto_install() {
  local command="" bundle="" start=0 device_arg=""
  while (($#)); do
    case "$1" in
      --start) start=1; shift ;;
      --device) device_arg="${2:?--device needs an id}"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      -*) die "unknown option: $1" ;;
      *)
        if [ -z "$command" ]; then command="$1"
        elif [ -z "$bundle" ]; then bundle="$1"
        else die "unexpected argument: $1"
        fi
        shift
        ;;
    esac
  done
  [ -n "$command" ] && [ -n "$bundle" ] ||
    die "usage: hap-app auto-install <app-command> <bundle-id> [--start] [--device <id>]"

  auto_install_guarded "$command" || exit 0

  local ready
  ready="$(probe_ready)"
  if [ "$ready" = "no-login" ] && enabled "$(auto_login_setting)" && ! login_recently_attempted; then
    mark_login_attempt
    log "需要登录华为开发者，正在打开浏览器（最多 ${HAP_APP_LOGIN_TIMEOUT:-120}s）"
    "$app_installer" login --timeout "${HAP_APP_LOGIN_TIMEOUT:-120}" >&2 || true
    ready="$(probe_ready)"
  fi

  local device=""
  case "$ready" in
    ok\ *) device="${ready#ok }" ;;
    no-login)
      queue_add "$command" "$bundle" login
      say "$command: 未登录华为开发者，已登记待装；运行 hap-app install-pending"
      exit 0
      ;;
    *)
      queue_add "$command" "$bundle" device
      say "$command: 设备未就绪（${ready:-unknown}），已登记待装；运行 hap-app install-pending"
      exit 0
      ;;
  esac

  install_one "$command" "$bundle" "$start" "$device"
}

cmd_install_pending() {
  local start=0 device_arg=""
  while (($#)); do
    case "$1" in
      --start) start=1; shift ;;
      --device) device_arg="${2:?--device needs an id}"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      *) die "unknown option: $1" ;;
    esac
  done
  command -v "$app_installer" >/dev/null 2>&1 || die "找不到 $app_installer"

  local -a names=()
  local name
  while IFS= read -r name; do
    [ -n "$name" ] && names+=("$name")
  done < <(queue_names)
  if ((${#names[@]} == 0)); then
    say "没有待装的应用"
    return 0
  fi

  local ready
  ready="$(probe_ready)"
  case "$ready" in
    no-login)
      log "需要登录华为开发者，正在打开浏览器…"
      "$app_installer" login >&2 || { log "登录未完成，未装机"; return 1; }
      ;;
    ok\ *) ;;
    *) log "设备未就绪（${ready:-unknown}）"; return 1 ;;
  esac

  local failed=0 installed=0 before after
  for name in "${names[@]}"; do
    local bundle device=""
    bundle="$(queue_field "$(queue_file "$name")" bundle)"
    if ! valid_command "$name" || ! valid_bundle "$bundle"; then
      log "丢弃损坏的队列条目：$name"
      queue_remove "$name"
      failed=$((failed + 1))
      continue
    fi
    [ -n "${device_arg:-}" ] && device="$device_arg"
    before="$(queue_names | wc -l | tr -d ' ')"
    install_one "$name" "$bundle" "$start" "$device"
    after="$(queue_names | wc -l | tr -d ' ')"
    if ((after < before)); then installed=$((installed + 1)); else failed=$((failed + 1)); fi
  done
  say "补装完成：$installed 个成功，$failed 个仍待装"
  ((failed == 0))
}

cmd_status() {
  local -a names=()
  local name
  while IFS= read -r name; do
    [ -n "$name" ] && names+=("$name")
  done < <(queue_names)
  if ((${#names[@]} == 0)); then
    say "没有待装的应用"
    return 0
  fi
  for name in "${names[@]}"; do
    local file
    file="$(queue_file "$name")"
    printf '%s\t%s\t%s\t%s\n' \
      "$name" \
      "$(queue_field "$file" bundle)" \
      "$(queue_field "$file" reason)" \
      "$(queue_field "$file" updated)"
  done
}

cmd_forget() {
  local name="${1:-}"
  [ -n "$name" ] || die "usage: hap-app forget <app-command>"
  valid_command "$name" || die "invalid app command: $name"
  queue_remove "$name"
  say "$name: 已从待装队列移除"
}

command_name="${1:-help}"
shift || true
case "$command_name" in
  auto-install) cmd_auto_install "$@" ;;
  install-pending) cmd_install_pending "$@" ;;
  status) cmd_status ;;
  forget) cmd_forget "$@" ;;
  -h|--help|help|"") usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac
