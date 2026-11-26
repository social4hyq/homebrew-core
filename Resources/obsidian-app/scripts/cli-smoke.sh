#!/usr/bin/env bash
# Real-device smoke test for the Obsidian CLI bridge on HarmonyOS PC.
# Prerequisites: app installed and running, CLI toggle enabled in
# Settings -> General -> Command line interface.
#
# The official CLI exits 0 even on errors, so every assertion inspects stdout
# content; exit codes are only used to catch hangs and tool failures.
set -euo pipefail

LOG_DIR="${CLI_SMOKE_LOG_DIR:-$HOME/.cache/obsidian-desktop/smoke}"
mkdir -p "$LOG_DIR"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="$LOG_DIR/smoke-$STAMP.log"

fail() { printf 'FAIL: %s\n' "$*" | tee -a "$OUT" >&2; exit 1; }
note() { printf 'ok: %s\n' "$*" | tee -a "$OUT"; }

# Prefer the bare entry point; fall back to the subcommand on older installs.
CLI=(obsidian-app cli)
if command -v obsidian >/dev/null 2>&1; then
  CLI=(obsidian)
fi

{
  printf '# CLI smoke %s\n' "$STAMP"
  printf 'device: %s\n' "$(hdc list targets 2>/dev/null | head -1)"
  printf 'entry: %s\n' "${CLI[*]}"
} >> "$OUT"

run_cli() {
  local label="$1"
  local raw="$OUT.$label.raw"
  timeout 20 "${CLI[@]}" "$@" > "$raw" 2>&1 || true
  if grep -qiE 'no CLI endpoint|cannot reach the app|is it running|unknown command|^Error:' "$raw"; then
    rm -f "$raw"
    fail "$label: error text in output"
  fi
  cat "$raw"
  rm -f "$raw"
}

app_state="$(timeout 20 obsidian-app status 2>&1)" || fail "status command failed"
[ "$app_state" = "running" ] || fail "app not running: $app_state"
note "app running"

CFG="$HOME/.cache/obsidian-desktop/cli.json"
[ -f "$CFG" ] || fail "no CLI endpoint at $CFG (enable Settings -> General -> Command line interface)"
python3 - "$CFG" <<'PY' || fail "malformed cli.json"
import json, sys
d = json.load(open(sys.argv[1]))
assert isinstance(d.get("port"), int)
assert isinstance(d.get("pid"), int)
assert isinstance(d.get("token"), str) and len(d["token"]) >= 16
PY
note "CLI endpoint present (token never printed)"

help_out="$(run_cli help)"
printf '%s' "$help_out" | grep -q 'Usage: obsidian' || fail "help missing Usage line"
note "help OK"

vaults_out="$(run_cli vaults)"
[ -n "$vaults_out" ] || fail "vaults returned empty"
note "vaults OK: $(printf '%s' "$vaults_out" | head -1)"

tags_out="$(run_cli tags counts)"
[ -n "$tags_out" ] || fail "tags counts returned empty"
note "tags counts OK"

aliases_out="$(run_cli aliases total)"
printf '%s' "$aliases_out" | grep -qE '^[0-9]+$' || fail "aliases total not numeric: $aliases_out"
note "aliases total OK"

printf 'PASS\n' >> "$OUT"
printf 'smoke passed; log: %s\n' "$OUT"
