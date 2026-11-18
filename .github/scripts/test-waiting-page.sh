#!/usr/bin/env bash
# Test for the shared waiting page (Resources/_shared/waiting-page).
#
# The apps' waiting.html used to be a copy per app; it is now rendered at build
# time from one template and a small strings file per app
# (Resources/<app>/app/waiting.json). The migration was done so that the page
# stays byte for byte what it was, and expected.sha256 pins that: every app that
# has a waiting.json must render to the hash recorded for it. A deliberate
# change of a page therefore shows up as a change of expected.sha256 in the same
# pull request. The renderer's strictness is tested here too.
# Needs bash, node and sha256sum.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIR="$ROOT/Resources/_shared/waiting-page"
RENDER="$DIR/render-waiting.cjs"
TEMPLATE="$DIR/waiting.html.in"
EXPECTED="$DIR/expected.sha256"
for f in "$RENDER" "$TEMPLATE" "$EXPECTED"; do
  [ -f "$f" ] || { echo "missing: $f" >&2; exit 2; }
done

T="$(mktemp -d "${TMPDIR:-/tmp}/waiting-page-test.XXXXXX")"
trap 'rm -rf "$T"' EXIT

PASS=0
FAILED=0
ok() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
bad() { FAILED=$((FAILED + 1)); printf 'FAIL - %s\n' "$1"; [ -z "${2:-}" ] || printf '       %s\n' "$2"; }

render() { node "$RENDER" "$@"; }
sha() { sha256sum "$1" | cut -d' ' -f1; }

# --- the pages -------------------------------------------------------------

apps=()
for strings in "$ROOT"/Resources/*/app/waiting.json; do
  [ -f "$strings" ] || continue
  apps+=("$(basename "$(dirname "$(dirname "$strings")")")")
done
[ "${#apps[@]}" -gt 0 ] || { bad "at least one app uses the shared waiting page" "no Resources/*/app/waiting.json found"; }

for app in ${apps[@]+"${apps[@]}"}; do
  want="$(awk -v a="$app" '$2 == a {print $1}' "$EXPECTED")"
  if [ -z "$want" ]; then
    bad "$app has a pinned hash" "add \"<sha256>  $app\" to Resources/_shared/waiting-page/expected.sha256"
    continue
  fi
  out="$T/$app.html"
  if ! render "$TEMPLATE" "$ROOT/Resources/$app/app/waiting.json" "$out" 2> "$T/err"; then
    bad "$app renders" "$(head -1 "$T/err")"
    continue
  fi
  got="$(sha "$out")"
  if [ "$got" = "$want" ]; then
    ok "$app renders to the pinned page ($(wc -c < "$out" | tr -d ' ') bytes)"
  else
    bad "$app renders to the pinned page" "got $got, pinned $want; if the page is meant to change, update expected.sha256 in the same pull request"
  fi
done

# The hash check must be able to fail: a changed value gives a different page.
if [ "${#apps[@]}" -gt 0 ]; then
  app="${apps[0]}"
  sed 's/"name": *"[^"]*"/"name": "Changed"/' "$ROOT/Resources/$app/app/waiting.json" > "$T/changed.json"
  render "$TEMPLATE" "$T/changed.json" "$T/changed.html"
  if [ "$(sha "$T/changed.html")" != "$(awk -v a="$app" '$2 == a {print $1}' "$EXPECTED")" ]; then
    ok "a changed value renders to a different page"
  else
    bad "a changed value renders to a different page" "the hash did not change"
  fi
fi

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
