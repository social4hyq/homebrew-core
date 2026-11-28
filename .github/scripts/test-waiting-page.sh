#!/usr/bin/env bash
# Test for the shared waiting page (Resources/_shared/waiting-page).
#
# Each app's waiting.html is rendered at build time from one shared template
# and a small strings file per app (Resources/<app>/app/waiting.json). This test
# checks that every app's strings render successfully and that the renderer's
# strictness guarantees hold (unknown/missing/unsafe values are rejected).
# Needs bash and node.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIR="$ROOT/Resources/_shared/waiting-page"
RENDER="$DIR/render-waiting.cjs"
TEMPLATE="$DIR/waiting.html.in"
CHECK="$DIR/check-waiting-commands.cjs"
for f in "$RENDER" "$TEMPLATE" "$CHECK"; do
  [ -f "$f" ] || { echo "missing: $f" >&2; exit 2; }
done

T="$(mktemp -d "${TMPDIR:-/tmp}/waiting-page-test.XXXXXX")"
trap 'rm -rf "$T"' EXIT

PASS=0
FAILED=0
ok() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
bad() { FAILED=$((FAILED + 1)); printf 'FAIL - %s\n' "$1"; [ -z "${2:-}" ] || printf '       %s\n' "$2"; }

render() { node "$RENDER" "$@"; }

# --- the pages -------------------------------------------------------------

apps=()
for strings in "$ROOT"/Resources/*/app/waiting.json; do
  [ -f "$strings" ] || continue
  apps+=("$(basename "$(dirname "$(dirname "$strings")")")")
done
[ "${#apps[@]}" -gt 0 ] || { bad "at least one app uses the shared waiting page" "no Resources/*/app/waiting.json found"; }

for app in ${apps[@]+"${apps[@]}"}; do
  out="$T/$app.html"
  if render "$TEMPLATE" "$ROOT/Resources/$app/app/waiting.json" "$out" 2> "$T/err"; then
    ok "$app renders ($(wc -c < "$out" | tr -d ' ') bytes)"
    # Each app's {{command}} is the complete `ohos-app install <id>` command.
    # The template must not append another "install"/"status"/"serve" to it:
    # a second "install" is a broken command, and the status command must be
    # `ohos-app status <id>` rather than `... install <id> status`.
    if node "$DIR/check-waiting-commands.cjs" "$ROOT/Resources/$app/app/waiting.json" "$out" > "$T/cmdout" 2> "$T/cmderr"; then
      ok "$app waiting-page commands are well-formed"
    else
      bad "$app waiting-page commands are well-formed" "$(head -1 "$T/cmderr")"
    fi
  else
    bad "$app renders" "$(head -1 "$T/err")"
  fi
done

# --- the renderer's strictness ----------------------------------------------

first="${apps[0]:-}"
if [ -n "$first" ]; then
  base="$ROOT/Resources/$first/app/waiting.json"
  expect_error() { # expect_error DESCRIPTION TEMPLATE STRINGS PATTERN
    if render "$2" "$3" "$T/e.html" 2> "$T/err"; then
      bad "$1" "the renderer accepted it"
    elif grep -q -- "$4" "$T/err"; then
      ok "$1"
    else
      bad "$1" "wrong error: $(head -1 "$T/err")"
    fi
  }
  node -e 'const fs=require("node:fs");const d=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
    const w=(n,o)=>fs.writeFileSync(process.argv[2]+"/"+n,JSON.stringify(o));
    const m={...d};delete m.wash;w("missing.json",m);
    w("extra.json",{...d,unused:"x"});
    w("unsafe.json",{...d,name:"A<b>"});
    w("quote.json",{...d,subtitle:"it\u0027s"});
    w("brace.json",{...d,name:"{{name}}"});
    w("empty.json",{...d,name:""});' "$base" "$T"
  sed 's/{{name}}/{{ name }}/' "$TEMPLATE" > "$T/malformed.in"
  expect_error "a placeholder without a value is an error" "$TEMPLATE" "$T/missing.json" "no value for"
  expect_error "a value no placeholder uses is an error" "$TEMPLATE" "$T/extra.json" "does not use it"
  expect_error "a value with markup is an error" "$TEMPLATE" "$T/unsafe.json" "must not contain"
  expect_error "a value with a quote is an error" "$TEMPLATE" "$T/quote.json" "must not contain"
  expect_error "a value with a brace pair is an error" "$TEMPLATE" "$T/brace.json" "must not contain"
  expect_error "an empty value is an error" "$TEMPLATE" "$T/empty.json" "non-empty"
  expect_error "a malformed placeholder is an error" "$T/malformed.in" "$base" "malformed placeholder"
  if node "$RENDER" "$TEMPLATE" "$base" > /dev/null 2>&1; then
    bad "wrong argument count is an error" "the renderer accepted two arguments"
  else
    ok "wrong argument count is an error"
  fi
fi

printf '\n%s passed, %s failed\n' "$PASS" "$FAILED"
[ "$FAILED" -eq 0 ]
