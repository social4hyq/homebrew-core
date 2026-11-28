#!/usr/bin/env bash
# Delegate Huawei Developer auth to the vendor CLI. ohos-hap holds no token:
# credentials stay in the vendor CLI's own state (~/.config/deveco-cli). This
# script is only ever invoked by an explicit `ohos-hap auth <subcommand>`.
#
# Environment:
#   OHOS_HAP_VENDOR_CLI   vendor CLI executable (default: devecocli on PATH)
#   OHOS_HAP_AUTH_NO_BROWSER=1   do not open the login URL in the system browser
#   OHOS_HAP_AUTH_TIMEOUT       bounded wait in seconds (default: 0, unbounded)
#   OHOS_HAP_USER_HOME          override HOME for the vendor CLI (tests/headless)
set -uo pipefail

CLI="${OHOS_HAP_VENDOR_CLI:-${DEVECO_CLI:-devecocli}}"
AA="${OHOS_HAP_AA:-/bin/aa}"
OPEN_BROWSER=1
TIMEOUT="${OHOS_HAP_AUTH_TIMEOUT:-0}"
[ "${OHOS_HAP_AUTH_NO_BROWSER:-0}" = "1" ] && OPEN_BROWSER=0

subcommand="${1:-}"
case "$subcommand" in
  login|logout|status) ;;
  *) echo "vendor-auth: usage: vendor-auth.sh login|logout|status" >&2; exit 2 ;;
esac

# The vendor CLI resolves its token from the real user's HOME. Auth runs in
# the user's interactive session (never from brew post_install), so HOME is
# already correct; the override exists for tests and headless environments.
if [ -n "${OHOS_HAP_USER_HOME:-}" ]; then
  export HOME="$OHOS_HAP_USER_HOME"
fi

if ! command -v "$CLI" >/dev/null 2>&1; then
  echo "vendor-auth: vendor CLI not found: $CLI" >&2
  echo "set OHOS_HAP_VENDOR_CLI to the devecocli executable path" >&2
  exit 2
fi

runner=()
if [ "$TIMEOUT" -gt 0 ] 2>/dev/null; then
  if command -v timeout >/dev/null 2>&1; then
    runner=(timeout "$TIMEOUT")
  else
    echo "vendor-auth: WARN: timeout not found; the login wait is unbounded" >&2
  fi
fi

case "$subcommand" in
  status)
    out="$("$CLI" auth status 2>&1)"
    rc=$?
    if [ "$rc" -ne 0 ]; then
      echo "unavailable"
      exit 2
    fi
    case "$out" in
      *'Not logged in'*|*'未登录'*) echo "not-logged-in" ;;
      *) echo "logged-in" ;;
    esac
    exit 0
    ;;
  logout)
    "${runner[@]}" "$CLI" auth logout
    exit $?
    ;;
  login)
    if [ "$OPEN_BROWSER" -eq 0 ]; then
      "${runner[@]}" "$CLI" auth login
      exit $?
    fi
    # devecocli cannot open a browser on OpenHarmony: it prints the login URL
    # then waits. Stream its output and open the first URL via the ability
    # manager. Failure to open is never fatal; the URL is still on stdout.
    opened=0
    url_re='https?://[A-Za-z0-9._~:/?#@!$&*+,;=%-]+'
    "${runner[@]}" "$CLI" auth login 2>&1 | while IFS= read -r line; do
      printf '%s\n' "$line"
      if [ "$opened" -eq 0 ] && [[ "$line" =~ $url_re ]]; then
        opened=1
        if [ -x "$AA" ] && "$AA" start -b com.huawei.hmos.browser -a MainAbility -U "${BASH_REMATCH[0]}" >/dev/null 2>&1; then
          # `aa start` returns success once the launch request is accepted; it
          # does not prove a browser window appeared (sandboxed shells start
          # the ability silently). Point the user at the printed URL either way.
          printf '%s\n' 'vendor-auth: requested browser launch via aa; if no window appears, open the URL above manually.'
        else
          printf '%s\n' 'vendor-auth: could not request browser launch; open the URL above by hand.'
        fi
      fi
    done
    exit "${PIPESTATUS[0]}"
    ;;
esac
