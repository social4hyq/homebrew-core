#!/usr/bin/env bash
# Install this tap's HAP apps on the connected device after `brew install` or
# `brew upgrade` has already done its part. The formula's post_install_steps
# call `hap-app auto-install <command> <bundle>`; when the device or the Huawei
# Developer login is missing, the app is queued instead and
# `hap-app install-pending` finishes it later.
#
# The auto path restores an app that was running, leaves a stopped app stopped,
# and never fails the brew install. It waits for one bounded Huawei Developer
# login by default; HAP_APP_AUTO_LOGIN=0 disables
# that. Configuration lives in $XDG_CONFIG_HOME/hap-app/config
# (`auto_install=0`, `auto_login=0`).

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
  # A marker proves this is the user's home. The second signal covers a clean
  # PC where none of the markers exists yet: this tap always installs into
  # <home>/.harmonybrew, so the prefix's parent is the home by construction.
  if [ -n "$candidate" ] && [ -d "$candidate" ] && {
    [ -e "$candidate/.HDCServer.pid" ] || [ -d "$candidate/.harmony" ] ||
      [ -d "$candidate/.hap-installer" ] || [ -d "$candidate/.app-installer" ] ||
      { [ -d "$candidate/.harmonybrew" ] && [ "$(basename "$HOMEBREW_PREFIX")" = ".harmonybrew" ] && [ -w "$candidate" ]; }
  }; then
    export HOME="$candidate"
  fi
}
recover_user_home

# Vendor downloads run before app-installer, so they need the same persistent
# network configuration as the DevEco CLI. Explicit shell settings always win.
load_network_config() {
  local file="$HOME/.app-installer/config" proxy no_proxy insecure
  [ -f "$file" ] || return 0
  if [ -z "${HTTPS_PROXY:-}${https_proxy:-}" ]; then
    proxy="$(sed -n 's/^[[:space:]]*https_proxy[[:space:]]*=[[:space:]]*//p' "$file" | tail -n 1)"
    [ -n "$proxy" ] && export HTTPS_PROXY="$proxy" https_proxy="$proxy"
  fi
  if [ -z "${NO_PROXY:-}${no_proxy:-}" ]; then
    no_proxy="$(sed -n 's/^[[:space:]]*no_proxy[[:space:]]*=[[:space:]]*//p' "$file" | tail -n 1)"
    [ -n "$no_proxy" ] && export NO_PROXY="$no_proxy" no_proxy="$no_proxy"
  fi
  if [ -z "${HAP_INSTALLER_TLS_INSECURE+x}" ]; then
    insecure="$(sed -n 's/^[[:space:]]*tls_insecure[[:space:]]*=[[:space:]]*//p' "$file" | tail -n 1)"
    if [ "$insecure" = "1" ]; then
      export HAP_INSTALLER_TLS_INSECURE=1
      printf '%s\n' 'hap-app: WARNING: tls_insecure=1 — vendor downloads that support this setting will skip TLS certificate verification.' >&2
    fi
  fi
}
load_network_config

# State lives under the (recovered) home so the post_install run and the user's
# own shells agree, even when XDG_CONFIG_HOME/XDG_CACHE_HOME point elsewhere.
config_dir="${HAP_APP_CONFIG_DIR:-$HOME/.config/hap-app}"
cache_dir="${HAP_APP_CACHE_DIR:-$HOME/.cache/hap-app}"
queue_dir="$cache_dir/pending"
log_dir="$cache_dir/logs"

verbose_setting() {
  local value="${HAP_APP_VERBOSE:-$(conf_get verbose)}"
  printf '%s' "${value:-0}"
}

pending_count() {
  local count=0 file
  for file in "$queue_dir"/*.json; do
    [ -e "$file" ] && count=$((count + 1))
  done
  printf '%s' "$count"
}

prune_logs() {
  [ -d "$log_dir" ] || return 0
  local old
  for old in $(ls -1t "$log_dir"/*.log 2>/dev/null | tail -n +21); do
    rm -f "$old"
  done
}

reason_label() {
  case "$1" in
    tls) printf '%s' 'TLS 证书链不受信' ;;
    network) printf '%s' '网络不可达' ;;
    login) printf '%s' '未登录华为开发者' ;;
    device) printf '%s' '设备不可用' ;;
    permissions) printf '%s' '权限校验未通过' ;;
    *) printf '%s' '安装失败' ;;
  esac
}

reason_hint() {
  case "$1" in
    tls) printf '%s' '在 ~/.app-installer/config 设置 tls_ca=/path/to/ca.pem 后运行 hap-app install-pending' ;;
    network) printf '%s' '检查网络/代理后运行 hap-app install-pending' ;;
    login) printf '%s' '运行 hap-app install-pending 完成华为开发者登录' ;;
    device) printf '%s' '连接并解锁设备后运行 hap-app install-pending' ;;
    permissions) printf '%s' '运行 hap-app status 查看缺失权限' ;;
    *) printf '%s' '查看日志或运行 hap-app status' ;;
  esac
}

stage_label() {
  case "$1" in
    prepare) printf '%s' '正在准备应用（可能需要下载厂商包）' ;;
    profile) printf '%s' '正在生成或刷新调试签名' ;;
    sign) printf '%s' '正在签名 HAP' ;;
    upload) printf '%s' '正在上传 HAP 到设备' ;;
    install) printf '%s' '正在安装到设备' ;;
    permissions) printf '%s' '正在校验应用权限' ;;
    *) return 1 ;;
  esac
}

report_stage() {
  local label
  label="$(stage_label "$1")" || return 0
  log "$label"
}

result_reason() {
  local file="$1"
  [ -f "$file" ] || return 0
  "$node_bin" -e 'const fs=require("node:fs");try{const v=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));process.stdout.write(String(v.reason||""))}catch{}' "$file" 2>/dev/null
}

result_detail() {
  local file="$1"
  [ -f "$file" ] || return 0
  "$node_bin" -e 'const fs=require("node:fs");try{const v=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));process.stdout.write(String(v.detail||"").slice(0,200))}catch{}' "$file" 2>/dev/null
}

# A TLS trust failure is deterministic until the CA configuration changes, so
# skip the next automatic attempts for a short while instead of paying the same
# timeout for every app in one brew run.
network_config_fingerprint() {
  local file="$HOME/.app-installer/config"
  [ -f "$file" ] || { printf 'none'; return; }
  stat -c '%Y-%s' "$file" 2>/dev/null || printf 'unknown'
}

tls_blocked_recently() {
  local marker="$cache_dir/tls-blocked" at fingerprint now
  [ -f "$marker" ] || return 1
  at="$(sed -n 's/^at=//p' "$marker" | tail -n 1)"
  fingerprint="$(sed -n 's/^config=//p' "$marker" | tail -n 1)"
  [[ "$at" =~ ^[0-9]+$ ]] || return 1
  now="$(date +%s)"
  ((now >= at && now - at < 600)) || return 1
  [ "$fingerprint" = "$(network_config_fingerprint)" ]
}

mark_tls_blocked() {
  mkdir -p "$cache_dir" 2>/dev/null || return 0
  printf 'at=%s\nconfig=%s\n' "$(date +%s)" "$(network_config_fingerprint)" >"$cache_dir/tls-blocked" 2>/dev/null || true
  chmod 600 "$cache_dir/tls-blocked" 2>/dev/null || true
}

clear_tls_blocked() {
  rm -f "$cache_dir/tls-blocked" 2>/dev/null || true
}

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
  status [--tsv]  Show the queued apps with the reason and the next step.
  logs [app-command]
                List retained logs, or print one app's latest full log.
  doctor [--network]
                Check device, login, signing and DevEco CLI compatibility.
  login [--timeout <s>]
                Huawei Developer login (what install-pending does when needed).
  forget <app-command>
                Remove one app from the queue.
  help          Show this help.

Generic HAP signing and installation are provided by app-installer.

Environment:
  HAP_APP_AUTO_INSTALL=0   Do not install or queue automatically (config file:
                           ~/.config/hap-app/config, auto_install=0)
  HAP_APP_AUTO_LOGIN=0     Do not open the Huawei Developer login automatically
                           (default: open it and wait HAP_APP_LOGIN_TIMEOUT
                           seconds, 120 by default; config: auto_login=0)
  HAP_APP_VERBOSE=1        Stream the full app install output instead of concise
                           stages (config file: verbose=1)
  HAP_APP_INSTALL_TIMEOUT  Overall install timeout in seconds (900)
  HAP_APP_USER_HOME        Override the home directory recovered from
                           HOMEBREW_PREFIX (for tests or unusual layouts)
  ~/.app-installer/config  https_proxy=... and no_proxy=... are restored for
                           vendor downloads and DevEco after postinstall;
                           tls_insecure=1 is forwarded to app installers;
                           explicit shell settings win
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
  printf '%s' "${value:-1}"
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

queue_entry_state() {
  local file
  file="$(queue_file "$1")"
  [ -f "$file" ] || { printf 'ok'; return; }
  "$node_bin" -e '
const fs = require("node:fs");
try {
  const value = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  process.stdout.write(value.v === undefined || value.v === 1 ? "ok" : "future");
} catch {
  process.stdout.write("broken");
}
' "$file" 2>/dev/null
}

queue_add() {
  local command="$1" bundle="$2" reason="$3" detail="${4:-}"
  valid_command "$command" || { log "invalid app command: $command"; return 1; }
  valid_bundle "$bundle" || { log "invalid bundle id: $bundle"; return 1; }
  mkdir -p "$queue_dir" || { log "cannot create $queue_dir"; return 1; }
  chmod 700 "$config_dir" "$queue_dir" 2>/dev/null || true
  local previous=0 attempts=1
  if [ -f "$(queue_file "$command")" ]; then
    previous="$(queue_field "$(queue_file "$command")" attempts)"
    [[ "$previous" =~ ^[0-9]+$ ]] || previous=0
    attempts=$((previous + 1))
  fi
  "$node_bin" -e '
const fs = require("node:fs");
const [file, command, bundle, reason, detail, attempts] = process.argv.slice(1);
const value = { v: 1, command, bundle, reason, detail, attempts: Number(attempts) || 1, updated: new Date().toISOString() };
const temporary = `${file}.${process.pid}.tmp`;
fs.writeFileSync(temporary, JSON.stringify(value) + "\n", { mode: 0o600 });
fs.chmodSync(temporary, 0o600);
fs.renameSync(temporary, file);
' "$(queue_file "$command")" "$command" "$bundle" "$reason" "$detail" "$attempts" ||
    { log "cannot write the pending queue"; return 1; }
}

queue_remove() {
  rm -f -- "$(queue_file "$1")"
}

queue_field() {
  "$node_bin" -e '
const fs = require("node:fs");
const value = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
if (value.v !== undefined && value.v !== 1) process.exit(2);
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
  local command="$1" bundle="$2" start="$3" device="${4:-}" stream="${5:-0}"
  local acl_file
  acl_file="$(acl_file_for "$command")"

  local -a env_args=(HAP_INSTALLER_NO_LOGIN=1)
  ((start)) || env_args+=(HAP_INSTALLER_NO_START=1 HAP_INSTALLER_RESTART_IF_RUNNING=1)
  [ -n "$device" ] && env_args+=(HAP_INSTALLER_DEVICE="$device")
  local -a timeout_args=()
  command -v timeout >/dev/null 2>&1 &&
    timeout_args=(timeout "${HAP_APP_INSTALL_TIMEOUT:-900}")

  mkdir -p "$log_dir" 2>/dev/null || true
  chmod 700 "$log_dir" 2>/dev/null || true
  local log_file result_file
  log_file="$log_dir/$(date -u +%Y%m%dT%H%M%SZ)-$command.log"
  : >"$log_file"
  chmod 600 "$log_file" 2>/dev/null || true
  result_file="$log_dir/result-$command.json"
  rm -f "$result_file" 2>/dev/null || true
  env_args+=(HAP_INSTALLER_RESULT_FILE="$result_file")

  install_status=queued
  if ((stream)); then
    log "installing $command${device:+（设备 $device）}…"
  else
    report_stage prepare
  fi
  local rc=0 line stage
  if ((stream)); then
    env "${env_args[@]}" "${timeout_args[@]}" "$command" install 2>&1 | tee "$log_file" >&2
    rc="${PIPESTATUS[0]}"
  else
    env "${env_args[@]}" HAP_APP_PROGRESS=1 "${timeout_args[@]}" "$command" install 2>&1 |
      while IFS= read -r line; do
        printf '%s\n' "$line" >>"$log_file"
        case "$line" in
          $'HAP_APP_STAGE\t'*)
            stage="${line#$'HAP_APP_STAGE\t'}"
            [[ "$stage" =~ ^[a-z]+$ ]] && report_stage "$stage"
            ;;
        esac
      done
    rc="${PIPESTATUS[0]}"
  fi
  if ((rc != 0)); then
    local reason
    reason="$(result_reason "$result_file")"
    [ -z "$reason" ] && reason=install-failed
    [ "$(probe_ready)" = "no-login" ] && reason=login
    queue_add "$command" "$bundle" "$reason" "$(result_detail "$result_file")"
    [ "$reason" = tls ] && mark_tls_blocked
    printf 'hap-app: ✖ %s 装机失败：%s（已登记，共 %s 个待装）\n' \
      "$command" "$(reason_label "$reason")" "$(pending_count)"
    printf 'hap-app:   → %s\n' "$(reason_hint "$reason")"
    printf 'hap-app:   日志：%s\n' "$log_file"
    prune_logs
    return 0
  fi
  rm -f "$result_file" 2>/dev/null || true

  ((stream)) || report_stage permissions
  local -a perms_args=(permissions --bundle-id "$bundle")
  [ -n "$acl_file" ] && perms_args+=(--expect-acl "$acl_file")
  local perms_rc=0 perms_out
  perms_out="$("$app_installer" "${perms_args[@]}" 2>&1)" || perms_rc=$?
  if ((perms_rc != 0)); then
    printf '%s\n' "$perms_out" >&2
    queue_add "$command" "$bundle" permissions
    printf 'hap-app: ✖ %s 权限校验未通过（已登记，共 %s 个待装）\n' "$command" "$(pending_count)"
    printf 'hap-app:   → %s\n' "$(reason_hint permissions)"
    printf 'hap-app:   日志：%s\n' "$log_file"
    prune_logs
    return 0
  fi

  queue_remove "$command"
  clear_tls_blocked
  install_status=installed
  say "$command: 已装机 $bundle${device:+（设备 $device）}"
  prune_logs
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

  local queue_state
  queue_state="$(queue_entry_state "$command")"
  if [ "$queue_state" != ok ]; then
    if [ "$queue_state" = future ]; then
      log "待装条目格式来自更新版本：$command（未覆盖；运行 hap-app forget $command 移除）"
    else
      log "队列条目损坏：$command（运行 hap-app forget $command 移除）"
    fi
    exit 0
  fi

  if tls_blocked_recently; then
    # Keep the original entry (and its detail): skipping is not a new attempt.
    [ -f "$(queue_file "$command")" ] || queue_add "$command" "$bundle" tls 'skipped: the last TLS trust failure is not fixed yet'
    say "$command: 已登记待装（同一签名服务刚因证书链失败，未重复尝试；共 $(pending_count) 个）；修复 tls_ca 后运行 hap-app install-pending"
    exit 0
  fi

  local login_attempted=0
  local ready
  ready="$(probe_ready)"
  if [ "$ready" = "no-login" ] && enabled "$(auto_login_setting)" && ! login_recently_attempted; then
    mark_login_attempt
    login_attempted=1
    log "需要登录华为开发者，正在打开浏览器（最多 ${HAP_APP_LOGIN_TIMEOUT:-120}s）"
    "$app_installer" login --timeout "${HAP_APP_LOGIN_TIMEOUT:-120}" >&2 || true
    ready="$(probe_ready)"
  fi

  local device="" stream=0
  if ((login_attempted)) || enabled "$(verbose_setting)"; then stream=1; fi
  case "$ready" in
    ok\ *) device="${ready#ok }" ;;
    no-login)
      queue_add "$command" "$bundle" login
      say "$command: 未登录华为开发者，已登记待装（共 $(pending_count) 个）；运行 hap-app install-pending 一次性完成"
      exit 0
      ;;
    *)
      queue_add "$command" "$bundle" device
      say "$command: 设备未就绪（${ready:-unknown}），已登记待装（共 $(pending_count) 个）；运行 hap-app install-pending 修复"
      exit 0
      ;;
  esac

  install_one "$command" "$bundle" "$start" "$device" "$stream"
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

  clear_tls_blocked
  local ready selected=""
  ready="$(probe_ready)"
  case "$ready" in
    no-login)
      log "需要登录华为开发者，正在打开浏览器…"
      "$app_installer" login >&2 || { log "登录未完成，未装机"; return 1; }
      ready="$(probe_ready)"
      ;;
  esac
  case "$ready" in
    ok\ *) selected="${ready#ok }" ;;
    *) log "设备未就绪（${ready:-unknown}）"; return 1 ;;
  esac
  [ -n "${device_arg:-}" ] && selected="$device_arg"

  local failed=0 installed=0
  for name in "${names[@]}"; do
    local bundle="" queue_state
    queue_state="$(queue_entry_state "$name")"
    if [ "$queue_state" != ok ]; then
      if [ "$queue_state" = future ]; then
        log "待装条目格式来自更新版本：$name（运行 hap-app forget $name 移除）"
      else
        log "队列条目损坏：$name（运行 hap-app forget $name 移除）"
      fi
      failed=$((failed + 1))
      continue
    fi
    bundle="$(queue_field "$(queue_file "$name")" bundle)"
    if ! valid_command "$name" || ! valid_bundle "$bundle"; then
      log "队列条目损坏：$name（运行 hap-app forget $name 移除）"
      failed=$((failed + 1))
      continue
    fi
    install_one "$name" "$bundle" "$start" "$selected" 1
    if [ "$install_status" = installed ]; then installed=$((installed + 1)); else failed=$((failed + 1)); fi
  done
  say "补装完成：$installed 个成功，$failed 个仍待装"
  if ((failed > 0)); then say "运行 hap-app status 查看剩余原因"; fi
  ((failed == 0))
}

cmd_status() {
  local tsv=0
  [ "${1:-}" = "--tsv" ] && tsv=1
  local -a names=()
  local name
  while IFS= read -r name; do
    [ -n "$name" ] && names+=("$name")
  done < <(queue_names)
  if ((${#names[@]} == 0)); then
    say "没有待装的应用"
  elif ((tsv)); then
    for name in "${names[@]}"; do
      local file queue_state
      file="$(queue_file "$name")"
      queue_state="$(queue_entry_state "$name")"
      if [ "$queue_state" != ok ]; then
        printf '%s\t\t%s\t\n' "$name" "$([ "$queue_state" = future ] && printf 'unsupported-version' || printf 'broken')"
        continue
      fi
      printf '%s\t%s\t%s\t%s\n' \
        "$name" \
        "$(queue_field "$file" bundle)" \
        "$(queue_field "$file" reason)" \
        "$(queue_field "$file" updated)"
    done
    return 0
  else
    say "待装 ${#names[@]} 个"
    for name in "${names[@]}"; do
      local file reason detail queue_state
      file="$(queue_file "$name")"
      queue_state="$(queue_entry_state "$name")"
      if [ "$queue_state" != ok ]; then
        printf '  %s  %s\n' "$name" "$([ "$queue_state" = future ] && printf '待装条目格式来自更新版本' || printf '队列条目损坏')"
        printf '    → 运行 hap-app forget %s 移除\n' "$name"
        continue
      fi
      reason="$(queue_field "$file" reason)"
      printf '  %s  %s  %s  %s\n' \
        "$name" "$(queue_field "$file" bundle)" "${reason:-unknown}" "$(queue_field "$file" updated)"
      printf '    → %s\n' "$(reason_hint "$reason")"
      detail="$(queue_field "$file" detail)"
      [ -n "$detail" ] && printf '    最近失败：%s\n' "$detail"
    done
  fi
  ((tsv)) && return 0
  printf 'hap-app: 配置：%s（verbose）、%s/.app-installer/config（tls_ca/https_proxy）\n' \
    "$config_dir/config" "$HOME"
  printf 'hap-app: 日志：%s（hap-app logs [app-command]）\n' "$log_dir"
}

cmd_logs() {
  (($# <= 1)) || die "usage: hap-app logs [app-command]"
  local name="${1:-}" file latest=""
  if [ -z "$name" ]; then
    for file in "$log_dir"/*.log; do
      [ -f "$file" ] || continue
      printf '%s\n' "$file"
      latest="$file"
    done
    [ -n "$latest" ] || say "没有保留的安装日志（目录：$log_dir）"
    return 0
  fi
  valid_command "$name" || die "invalid app command: $name"
  for file in "$log_dir"/*-"$name".log; do
    [ -f "$file" ] || continue
    latest="$file"
    break
  done
  [ -n "$latest" ] || die "没有 $name 的日志（目录：$log_dir）"
  cat "$latest"
}

cmd_doctor() {
  command -v "$app_installer" >/dev/null 2>&1 || die "找不到 $app_installer"
  exec "$app_installer" doctor "$@"
}

cmd_login() {
  command -v "$app_installer" >/dev/null 2>&1 || die "找不到 $app_installer"
  exec "$app_installer" login "$@"
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
  status) cmd_status "$@" ;;
  logs) cmd_logs "$@" ;;
  doctor) cmd_doctor "$@" ;;
  login) cmd_login "$@" ;;
  forget) cmd_forget "$@" ;;
  -h|--help|help|"") usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac
