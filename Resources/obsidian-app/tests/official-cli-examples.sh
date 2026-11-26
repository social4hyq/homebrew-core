#!/usr/bin/env bash
# Verify every command example on https://obsidian.md/cli against the ported
# bare `obsidian` CLI. Mutating commands are executed and then rolled back by
# restoring the vault from a backup taken before the run.
set -uo pipefail

VAULT="/storage/Users/currentUser/Obsidian/Obsidian Vault"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="/storage/Users/currentUser/HarmonyPC/Software/ohos-obsidian-desktop/logs/cli-bridge"
LOG="$LOG_DIR/official-examples-$STAMP.log"
BACKUP="/data/storage/el2/base/cache/opencode/obsidian-vault-backup-$STAMP"
SHOT="/data/storage/el2/base/cache/opencode/obsidian-shot-$STAMP.png"

mkdir -p "$LOG_DIR" "/data/storage/el2/base/cache/opencode"
[ -d "$VAULT" ] || { echo "vault missing: $VAULT" >&2; exit 1; }
cp -a "$VAULT" "$BACKUP" || exit 1

before="$(find "$VAULT" -type f | sed "s|^$VAULT/||" | sort)"

cleanup() {
  local f
  comm -13 <(printf '%s\n' "$before") \
           <(find "$VAULT" -type f | sed "s|^$VAULT/||" | sort) |
    while IFS= read -r f; do rm -f "$VAULT/$f"; done
  cp -a "$BACKUP/." "$VAULT/"
  obsidian reload >/dev/null 2>&1 || true
  rm -rf "$BACKUP"
  printf '\n[cleanup] vault restored\n' >> "$LOG"
}
trap cleanup EXIT

run() {
  local label="$1"
  shift
  printf '\n===== %s =====\n$ obsidian' "$label" >> "$LOG"
  printf ' %q' "$@" >> "$LOG"
  printf '\n' >> "$LOG"
  local out rc
  out="$(timeout 25 obsidian "$@" 2>&1)"
  rc=$?
  printf '%s\n' "$out" | head -20 >> "$LOG"
  printf '[exit=%s]\n' "$rc" >> "$LOG"
}

{
  printf '# Official CLI examples verification — %s\n' "$STAMP"
  printf 'entry: %s\n' "$(command -v obsidian)"
  printf 'app: %s\n' "$(obsidian-app --help 2>&1 | head -1)"
} >> "$LOG"

# --- Get started -----------------------------------------------------------
run "help" help
# TUI is exercised separately with a pseudo-terminal (no argv).

# --- Basics ----------------------------------------------------------------
run "daily" daily
run "search meeting notes" search 'query=meeting notes'
run "daily:append" daily:append 'content=- [ ] Buy groceries'
run "read" read
run "tasks daily" tasks daily
run "create from template (exact example)" create 'name=Trip to Paris' template=Travel
run "tags counts" tags counts
run "diff README (exact example)" diff file=README from=1 to=3

# --- Developers ------------------------------------------------------------
run "devtools (open)" devtools
run "devtools (close)" devtools
run "plugin:reload" plugin:reload id=obsidian-importer
run "dev:screenshot" dev:screenshot "path=$SHOT"
if [ -f "$SHOT" ]; then
  printf '[screenshot] created: %s bytes=%s\n' "$SHOT" "$(wc -c < "$SHOT")" >> "$LOG"
else
  printf '[screenshot] NOT created\n' >> "$LOG"
fi
run "eval getFiles length" eval 'code=app.vault.getFiles().length'
run "dev:errors" dev:errors
run "dev:css workspace" dev:css 'selector=.workspace'
run "dev:dom nav" dev:dom 'selector=.nav'

# --- Automation ------------------------------------------------------------
run "daily:append review inbox" daily:append 'content=- [ ] Review inbox'
run "daily:append check calendar" daily:append 'content=- [ ] Check calendar'
run "recents --copy" recents --copy
run "unresolved" unresolved
run "vault=Notes search (exact example)" 'vault=Notes' search 'query=status::active' format=json
# Adapted variants where the example's fixture does not exist in this vault:
run "create without template (adapted)" create 'name=CLI 验证临时笔记'
run "diff real file (adapted)" diff file=2026-11-26 from=1 to=2
run "vault=Obsidian Vault search (adapted)" 'vault=Obsidian Vault' search 'query=status::active' format=json

printf '\n[DONE] log: %s\n' "$LOG"
