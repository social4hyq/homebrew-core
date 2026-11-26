#!/usr/bin/env bash
# TDD test for the bare `obsidian` CLI entry point.
# Runs directly against tap worktree resources; no brew install required.
set -euo pipefail

WT="${1:?usage: $0 <tap-worktree-root>}"
ROOT="$WT/Resources/obsidian-app/scripts"
ENTRY="$ROOT/obsidian-cli-entry.sh"
CLI="$ROOT/obsidian-cli.cjs"
DESKTOP="$ROOT/obsidian-desktop.sh"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
ok() { printf 'ok: %s\n' "$*"; }

[ -f "$ENTRY" ] || fail "entry script missing: $ENTRY"
bash -n "$ENTRY" || fail "entry script syntax error"

tmp=$(mktemp -d /data/storage/el2/base/cache/opencode/obsidian-cli-entry.XXXXXX)
trap 'rm -rf "$tmp"' EXIT

# Fake node: record argv and emit a marker so we can verify pass-through.
cat > "$tmp/node" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$FAKE_NODE_LOG"
printf '__CLI_CALLED__\n'
SH
chmod +x "$tmp/node"

# 1. CLI path + all args (including one with spaces) forwarded verbatim.
FAKE_NODE_LOG="$tmp/args" \
OBSIDIAN_DESKTOP_NODE="$tmp/node" \
OBSIDIAN_DESKTOP_CLI="$CLI" \
  bash "$ENTRY" --help 'daily:append content=- [ ] Buy groceries' > "$tmp/out"

grep -q '__CLI_CALLED__' "$tmp/out" || fail "CLI was not invoked"
[ "$(sed -n '1p' "$tmp/args")" = "$CLI" ] || fail "CLI path wrong: $(sed -n '1p' "$tmp/args")"
[ "$(sed -n '2p' "$tmp/args")" = '--help' ] || fail "arg 1 not forwarded"
[ "$(sed -n '3p' "$tmp/args")" = 'daily:append content=- [ ] Buy groceries' ] \
  || fail "arg with spaces not forwarded verbatim"
ok "argv forwarded verbatim"

# 2. Missing CLI client path fails loudly instead of silently running node.
set +e
missing=$(OBSIDIAN_DESKTOP_NODE="$tmp/node" bash "$ENTRY" help 2>&1)
rc=$?
set -e
[ "$rc" -ne 0 ] || fail "missing OBSIDIAN_DESKTOP_CLI should fail"
printf '%s' "$missing" | grep -q 'missing CLI client' || fail "missing-CLI error message absent"
ok "missing CLI path fails loudly"

# 3. Management surface stays intact (the new entry must not eat these).
for cmd in install start stop status uninstall cli; do
  grep -qE "^[[:space:]]+$cmd\)" "$DESKTOP" || fail "management command lost: $cmd"
done
ok "obsidian-app management commands intact"
