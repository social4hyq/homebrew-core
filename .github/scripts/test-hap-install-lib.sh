#!/usr/bin/env bash
# Standalone test for Resources/_shared/hap-app/install-lib.sh.
#
# Runs the shared install flow through a fixture app script with a fake
# app-installer and a minimal HAP built on the fly, so a change to the library
# gets feedback in seconds instead of after a 20-minute formula build.
# Needs bash, node, zip and unzip.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB="${HAP_APP_INSTALL_LIB:-$ROOT/Resources/_shared/hap-app/install-lib.sh}"
[ -f "$LIB" ] || { echo "install-lib.sh not found: $LIB" >&2; exit 2; }

T="$(mktemp -d "${TMPDIR:-/tmp}/hap-install-lib-test.XXXXXX")"
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin" "$T/tmp" "$T/home" "$T/hap-tree/resources/resfile/resources/app"

PASS=0
FAILED=0
ok() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
bad() { FAILED=$((FAILED + 1)); printf 'FAIL - %s\n' "$1"; [ -z "${2:-}" ] || printf '       %s\n' "$2"; }
check() { # check DESCRIPTION CONDITION...
  local desc="$1"; shift
  if "$@"; then ok "$desc"; else bad "$desc"; fi
}

# --- fixtures -------------------------------------------------------------

# Unsigned HAP: its own module.json (one permission) and a placeholder config.
printf '%s' '{"app":{"bundleName":"com.test.app"},"module":{"requestPermissions":[{"name":"ohos.permission.INTERNET"}]}}' > "$T/hap-tree/module.json"
printf '%s' '{"port":0}' > "$T/hap-tree/resources/resfile/resources/app/config.json"
(cd "$T/hap-tree" && zip -q -X "$T/shell.hap" module.json resources/resfile/resources/app/config.json)

# ACL variant of module.json: same bundle, one extra permission.
printf '%s' '{"app":{"bundleName":"com.test.app"},"module":{"requestPermissions":[{"name":"ohos.permission.INTERNET"},{"name":"ohos.permission.CUSTOM_SANDBOX"}]}}' > "$T/module-acl.json"
# A module.json for a different bundle, to trigger the mismatch check.
printf '%s' '{"app":{"bundleName":"com.other.app"},"module":{"requestPermissions":[]}}' > "$T/module-acl-other.json"
printf '%s' '{"port":4242}' > "$T/host-config.json"

# Fake app-installer: records its arguments, keeps the HAP it was given and
# writes the signed HAP it was asked for. FAKE_FAIL=1 makes it fail.
cat > "$T/bin/app-installer" <<'SH'
#!/bin/sh
printf '%s\n' "$@" > "$FAKE_ARGS"
echo "FileTransfer progress noise"
echo "login: https://example.invalid/login"
while [ $# -gt 0 ]; do
  case "$1" in
    --hap) cp "$2" "$FAKE_HAP"; shift 2 ;;
    --signed-hap) echo signed > "$2"; shift 2 ;;
    *) shift ;;
  esac
done
[ "${FAKE_FAIL:-0}" = 1 ] && { echo "installer exploded" >&2; exit 3; }
exit 0
SH
chmod 0755 "$T/bin/app-installer"

# Fixture app script: what a real per-app install-desktop.sh looks like.
cat > "$T/app.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
APP_CMD=testapp
ENV_PREFIX=TESTAPP
BUNDLE_ID_DEFAULT=com.test.app
APP_NAME_DEFAULT=TestApp
FLAVOR=plain
if [ "${FIXTURE_NO_CONFIG:-0}" = 1 ]; then NEED_CONFIG=0; fi
if [ -n "${FIXTURE_EXTRA_TOOL:-}" ]; then EXTRA_TOOLS=("$FIXTURE_EXTRA_TOOL"); fi
stage_tree() {
  mkdir -p "$2/resources/resfile/resources/app"
  node -e 'const fs=require("node:fs"); const [src,dst,flavor]=process.argv.slice(1);
    const port = src ? JSON.parse(fs.readFileSync(src,"utf8")).port : 0;
    fs.writeFileSync(dst, JSON.stringify({port, flavor}) + "\n");' \
    "$1" "$2/resources/resfile/resources/app/config.json" "$FLAVOR"
}
app_usage_extra() { echo '  --flavor X     fixture option'; }
app_parse_option() {
  case "$1" in
    --flavor) FLAVOR="${2:?--flavor needs a value}"; OPT_SHIFT=2 ;;
  esac
}
app_prepare() { [ -z "${FIXTURE_PREPARE_MARK:-}" ] || : > "$FIXTURE_PREPARE_MARK"; }
. "$LIB"
SH

# --- helpers --------------------------------------------------------------

OUT="$T/out"; ERR="$T/err"; RC=0
run() { # run [env VAR=val ...] -- ARGS...
  local envs=()
  while [ $# -gt 0 ] && [ "$1" != "--" ]; do envs+=("$1"); shift; done
  [ $# -eq 0 ] || shift
  rm -f "$T/args" "$T/injected.hap"
  set +e
  env PATH="$T/bin:$PATH" TMPDIR="$T/tmp" HOME="$T/home" LIB="$LIB" \
      TESTAPP_UNSIGNED_HAP="$T/shell.hap" TESTAPP_MODULE_ACL="$T/module-acl.json" \
      TESTAPP_HDC_DEFAULT=/fake/hdc FAKE_ARGS="$T/args" FAKE_HAP="$T/injected.hap" \
      ${envs[@]+"${envs[@]}"} \
      bash "$T/app.sh" "$@" >"$OUT" 2>"$ERR"
  RC=$?
  set -e
}
member() { unzip -p "$1" "$2" 2>/dev/null; }
perm_count() { member "$1" module.json | node -e 'let s="";process.stdin.on("data",c=>s+=c).on("end",()=>console.log(JSON.parse(s).module.requestPermissions.length))'; }
arg_after() { awk -v k="$1" 'prev==k {print; exit} {prev=$0}' "$T/args"; }
leftovers() { find "$T/tmp" -maxdepth 1 -name 'testapp-inject.*' | wc -l | tr -d ' '; }
contains() { grep -qF -- "$2" "$1"; }
lacks() { ! grep -qF -- "$2" "$1"; }
lacks_line() { ! grep -qxF -- "$2" "$1"; }

# --- scenarios ------------------------------------------------------------

# 1. Default: ACL variant, config injected, installer called with the right arguments.
run -- --config "$T/host-config.json"
check "default install exits 0" test "$RC" -eq 0
check "result line goes to stdout with the ACL variant" contains "$OUT" "installed (com.test.app, ACL)"
check "stdout carries only the result line" test "$(wc -l < "$OUT" | tr -d ' ')" -eq 1
check "ACL module.json replaced the HAP's own (2 permissions)" test "$(perm_count "$T/injected.hap")" -eq 2
check "per-host config was staged into the HAP" test "$(member "$T/injected.hap" resources/resfile/resources/app/config.json)" = '{"port":4242,"flavor":"plain"}'
check "bundle id passed to app-installer" test "$(arg_after --bundle-id)" = com.test.app
check "app name passed to app-installer" test "$(arg_after --app-name)" = TestApp
check "module and ability passed to app-installer" test "$(arg_after --module)/$(arg_after --ability)" = electron/EntryAbility
check "hdc default from the wrapper environment is used" test "$(arg_after --hdc)" = /fake/hdc
check "installer progress noise is filtered from stderr" lacks "$ERR" FileTransfer
check "login URL is streamed to stderr" contains "$ERR" "https://example.invalid/login"
check "temporary stage directory is removed" test "$(leftovers)" -eq 0
check "no --device unless asked" lacks_line "$T/args" --device

# 2. --no-acl keeps the HAP's own module.json.
run -- --config "$T/host-config.json" --no-acl
check "--no-acl exits 0" test "$RC" -eq 0
check "--no-acl reports the strong-sandbox variant" contains "$OUT" "installed (com.test.app, strong-sandbox)"
check "--no-acl keeps the HAP's own permissions (1)" test "$(perm_count "$T/injected.hap")" -eq 1

# 3. A module-acl.json for another bundle is rejected before anything is installed.
run TESTAPP_MODULE_ACL="$T/module-acl-other.json" -- --config "$T/host-config.json"
check "bundle mismatch fails" test "$RC" -ne 0
check "bundle mismatch names both bundles" contains "$ERR" "module-acl.json targets com.other.app but the HAP is com.test.app"
check "bundle mismatch never reaches app-installer" test ! -e "$T/args"

# 4. Missing ACL file falls back to the strong-sandbox variant with a warning.
run TESTAPP_MODULE_ACL="$T/does-not-exist.json" -- --config "$T/host-config.json"
check "missing ACL file still installs" test "$RC" -eq 0
check "missing ACL file warns" contains "$ERR" "ACL module.json missing"
check "missing ACL file falls back to strong-sandbox" contains "$OUT" "strong-sandbox"

# 5. --keep copies the signed HAP out of the stage directory.
run -- --config "$T/host-config.json" --keep
check "--keep exits 0" test "$RC" -eq 0
check "--keep leaves the signed HAP in TMPDIR" test -f "$T/tmp/testapp-signed.hap"
check "--keep prints where the HAP went" contains "$ERR" "signed HAP kept at $T/tmp/testapp-signed.hap"
rm -f "$T/tmp/testapp-signed.hap"
run KEEP_NAME_PROBE=1 -- --config "$T/host-config.json"
check "without --keep nothing is left behind" test ! -e "$T/tmp/testapp-signed.hap"

# 6. --device is passed through.
run -- --config "$T/host-config.json" --device ABC123
check "--device is forwarded to app-installer" test "$(arg_after --device)" = ABC123

# 7. --hap overrides the wrapper's HAP.
cp "$T/shell.hap" "$T/other.hap"
run TESTAPP_UNSIGNED_HAP=/nonexistent.hap -- --config "$T/host-config.json" --hap "$T/other.hap"
check "--hap overrides the environment" test "$RC" -eq 0

# 8. Errors.
run -- --config "$T/missing-config.json"
check "missing config file fails" test "$RC" -ne 0
check "missing config file says so" contains "$ERR" "host config not found"
run --
check "no --config fails when the app needs one" test "$RC" -ne 0
run -- --config "$T/host-config.json" --bogus
check "unknown option fails" test "$RC" -ne 0
check "unknown option is named" contains "$ERR" "unknown argument: --bogus"
run TESTAPP_UNSIGNED_HAP= -- --config "$T/host-config.json"
check "no HAP at all fails" test "$RC" -ne 0
check "no HAP at all explains how to set one" contains "$ERR" "set TESTAPP_UNSIGNED_HAP or pass --hap"
run TESTAPP_UNSIGNED_HAP="$T/nonexistent.hap" -- --config "$T/host-config.json"
check "nonexistent HAP fails" test "$RC" -ne 0
run FAKE_FAIL=1 -- --config "$T/host-config.json"
check "app-installer failure fails the install" test "$RC" -ne 0
check "app-installer failure reports it" contains "$ERR" "installation failed"
check "app-installer failure prints no result line" test ! -s "$OUT"
check "stage directory is removed after a failure too" test "$(leftovers)" -eq 0
run FIXTURE_EXTRA_TOOL=definitely-not-a-tool -- --config "$T/host-config.json"
check "a missing EXTRA_TOOLS entry fails" test "$RC" -ne 0
check "a missing EXTRA_TOOLS entry is named" contains "$ERR" "definitely-not-a-tool not found"

# 9. Per-app hooks.
run -- --config "$T/host-config.json" --flavor spicy
check "app_parse_option consumes its option" test "$RC" -eq 0
check "app_parse_option's value reaches stage_tree" test "$(member "$T/injected.hap" resources/resfile/resources/app/config.json)" = '{"port":4242,"flavor":"spicy"}'
run FIXTURE_PREPARE_MARK="$T/prepared" -- --config "$T/host-config.json"
check "app_prepare runs" test -f "$T/prepared"
run FIXTURE_NO_CONFIG=1 --
check "NEED_CONFIG=0 installs without --config" test "$RC" -eq 0
run -- --help
check "--help exits 0" test "$RC" -eq 0
check "--help lists the shared options" contains "$OUT" "--no-acl"
check "--help lists the app's own options" contains "$OUT" "--flavor X"
check "--help prints no result line" lacks "$OUT" "installed ("

printf '\n%s passed, %s failed\n' "$PASS" "$FAILED"
[ "$FAILED" -eq 0 ]
