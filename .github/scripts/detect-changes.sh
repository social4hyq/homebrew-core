#!/bin/bash
# Classify formulae changed between $BEFORE and $AFTER into build / heavy /
# changed lists (JSON arrays written to $GITHUB_OUTPUT). Bottle-block-only
# changes are skipped; names in $HEAVY_FORMULAS get light checks only.
set -euo pipefail

if [[ "$BEFORE" =~ ^0+$ ]] || ! git cat-file -e "$BEFORE" 2>/dev/null; then
  echo "::warning::event.before unavailable (new branch/force push), comparing HEAD^..HEAD"
  BEFORE=$(git rev-parse "$AFTER^")
fi

# On a pull request $BEFORE is the tip of the base branch, which can be ahead
# of the point the PR branch was forked from. Diffing against it would list
# everything that landed on the base branch since as reverted by the PR, and
# rebuild those formulae from the branch's stale copy (and push a stale bottle
# to the PR branch). Start from the merge base so only the PR's own changes
# count. For a push $BEFORE is an ancestor of $AFTER and stays as it is.
if MERGE_BASE=$(git merge-base "$BEFORE" "$AFTER" 2>/dev/null) && [ -n "$MERGE_BASE" ] \
   && [ "$MERGE_BASE" != "$BEFORE" ]; then
  echo "::notice::$BEFORE is not an ancestor of $AFTER (branch behind its base): comparing from the merge base $MERGE_BASE"
  BEFORE="$MERGE_BASE"
fi

# Skip entirely when $AFTER is our own bottle write-back commit
# (`brew bottle --write` commits as "<formula>: add/update <ver> bottle.").
# Reads the actual commit message rather than the triggering event's payload
# shape, so the same check works for push (publish-on-merge.yml) and
# pull_request (pr-validate.yml, which has no head_commit.message equivalent
# to check at the job-`if:` level) alike — one guard instead of two
# per-workflow, event-specific ones.
BOTTLE_COMMIT_RE='^[^[:space:]]+: (add|update) .+ bottle\.$'

HEAD_MSG=$(git log -1 --format=%s "$AFTER")
if [[ "$HEAD_MSG" =~ $BOTTLE_COMMIT_RE ]]; then
  echo "::notice::HEAD is a bottle write-back commit ($HEAD_MSG), skipping"
  {
    echo "build=[]"
    echo "changed=[]"
    echo "heavy=[]"
  } >> "$GITHUB_OUTPUT"
  echo "### detect-changes" >> "$GITHUB_STEP_SUMMARY"
  echo "- skipped: HEAD is a bottle write-back commit ($HEAD_MSG)" >> "$GITHUB_STEP_SUMMARY"
  exit 0
fi

#  `brew bottle --write` inserts a blank line on both sides of a newly added
# bottle block; stripping the block alone leaves a doubled blank line behind
# that isn't in the pre-bottle version, so the very first bottle a formula
# gets makes this comparison see a false non-bottle diff (verified 2026-07-20:
# ci-smoke-test's first bottle commit triggered a spurious full rebuild).
# `cat -s` squeezes consecutive blank lines on both sides of the diff so that
# extra line washes out symmetrically without also hiding a real content
# change (confirmed against icu4c@78's routine bottle-only update history).
strip_bottle() { sed '/^  bottle do$/,/^  end$/d' | cat -s; }

# Strip full-line comments for the comment-only skip below, but leave heredoc
# bodies verbatim: heredoc content (shell/CMake/Rust/zsh-completion wrapper
# text) IS code that lands in the bottle, so `#`-prefixed lines inside `<<~EOS`
# (e.g. `#!/bin/sh`, `#compdef`) must not be treated as comments — otherwise an
# edit to a comment line inside a wrapper heredoc would be misread as
# "comment-only" and its rebuild skipped. Delimiters seen in this tap: <<~EOS,
# <<~SH, <<~'ZSH', … — the optional quote is matched via the '\'' in the
# bracket class. Ruby `args << "-D..."` (Array#<<) is not a heredoc and is
# ignored because the token after `<<` starts with `-`/`"`, not an identifier.
strip_comments() {
  awk '
    function hd(line,   m, d) {
      if (match(line, /<<[-~]?[[:space:]]*['\''"]?[A-Za-z_][A-Za-z0-9_]*/)) {
        d = substr(line, RSTART, RLENGTH)
        sub(/^<<[-~]?[[:space:]]*/, "", d)
        gsub(/['\''"]/, "", d)
        return d
      }
      return ""
    }
    {
      if (here) {
        print
        t = $0
        sub(/^[[:space:]]+/, "", t)
        sub(/[[:space:]]+$/, "", t)
        if (t == here) here = ""
        next
      }
      d = hd($0)
      if (d != "") { print; here = d; next }
      if ($0 ~ /^[[:space:]]*#/) next
      print
    }
  ' | cat -s
}

# Strip a whole `def caveats ... end` method. caveats is user-facing hint text
# that never lands in the bottle, so adding/changing/removing it must not
# trigger a rebuild. Track heredocs so an `end` inside wrapper text is not
# mistaken for the method's own end; the method end is the `end` at the exact
# indentation of `def caveats`.
strip_caveats() {
  awk '
    function hd(line,   d) {
      if (match(line, /<<[-~]?[[:space:]]*['\''"]?[A-Za-z_][A-Za-z0-9_]*/)) {
        d = substr(line, RSTART, RLENGTH)
        sub(/^<<[-~]?[[:space:]]*/, "", d)
        gsub(/['\''"]/, "", d)
        return d
      }
      return ""
    }
    {
      if (incav) {
        if (here) {
          t = $0; sub(/^[[:space:]]+/, "", t); sub(/[[:space:]]+$/, "", t)
          if (t == here) here = ""
          next
        }
        if ($0 ~ ("^" cavind "end[[:space:]]*$")) { incav = 0; next }
        d = hd($0)
        if (d != "") { here = d; next }
        next
      }
      if (match($0, /def caveats([[:space:]]|$)/)) {
        cavind = substr($0, 1, RSTART - 1)
        incav = 1
        next
      }
      print
    }
  ' | cat -s
}

mapfile -t FILES < <(git diff --name-status --no-renames "$BEFORE" "$AFTER" -- 'Formula/' \
  | awk '$1 != "D" && $2 ~ /^Formula\/[^\/]+\/[^\/]+\.rb$/ {print $2}')

BUILD=(); HEAVY=(); CHANGED=()
for f in "${FILES[@]}"; do
  name=$(basename "$f" .rb)
  [[ "$name" =~ ^[A-Za-z0-9@+._-]+$ ]] \
    || { echo "::error::invalid formula name: $name"; exit 1; }
  CHANGED+=("$name")

  # already has a matching bottle: if the LAST commit to ever touch this
  # specific file (as of $AFTER) is a bot write-back, someone (pr-validate.yml
  # publishing from a PR branch, or a manual bottle-build.yml upload=true run)
  # already built and published this exact content — skip regardless of what
  # else is in the $BEFORE..$AFTER range. This is the common case now: a
  # merged PR's cumulative diff always shows real non-bottle changes (the
  # whole point of the PR), which defeats the plain before/after strip_bottle
  # comparison below even though the file's bottle is already correct
  # (confirmed 2026-07-20 via PR #31: a REGULAR, non-squash merge still
  # triggered a redundant post-merge rebuild for exactly this reason — the
  # squash-merge fix alone was incomplete).
  LAST_TOUCH_MSG=$(git log -1 --format=%s "$AFTER" -- "$f")
  if [[ "$LAST_TOUCH_MSG" =~ $BOTTLE_COMMIT_RE ]]; then
    echo "::notice::$name: already has a bottle from its own last commit ($LAST_TOUCH_MSG), skipping build"
    continue
  fi

  # bottle-block-only changes don't need a rebuild (the narrower case: a
  # rebuild with no source change at all, e.g. a direct bottle-build.yml
  # upload=true dispatch against main)
  if git cat-file -e "$BEFORE:$f" 2>/dev/null && \
     diff <(git show "$BEFORE:$f" | strip_bottle) \
          <(git show "$AFTER:$f"  | strip_bottle) >/dev/null; then
    echo "::notice::$name: bottle block only, skipping build"
    continue
  fi

  # comment-only changes don't need a rebuild either: stripping both the
  # bottle block and full-line comments leaves nothing, so the install logic
  # (and therefore the bottle content) is byte-for-byte identical. Wrapper
  # edits still rebuild — heredoc bodies survive strip_comments, so a real
  # wrapper change stays visible in the diff.
  if git cat-file -e "$BEFORE:$f" 2>/dev/null && \
     diff <(git show "$BEFORE:$f" | strip_bottle | strip_caveats | strip_comments | grep -v '^[[:space:]]*$') \
          <(git show "$AFTER:$f"  | strip_bottle | strip_caveats | strip_comments | grep -v '^[[:space:]]*$') >/dev/null; then
    echo "::notice::$name: comment/caveats only, skipping build"
    continue
  fi
  if tr ' ' '\n' <<< "$HEAVY_FORMULAS" | grep -qx "$name"; then
    HEAVY+=("$name")
  else
    BUILD+=("$name")
  fi
done

# Changes under Patches/<f>/ or Resources/<f>/ alter the bottle of formula <f>
# even when Formula/**/<f>.rb is untouched, and Resources/_shared/<x>/ alters
# every formula whose source mentions "Resources/_shared/<x>". The bottle-only /
# comment-only skips above judge the .rb text alone, so these formulae are
# added here, after them. They build unless the formula's own last commit is a
# bottle write-back that already contains those asset changes (see
# bottled_since_assets below).
mapfile -t ASSET_FILES < <(git diff --name-only --no-renames "$BEFORE" "$AFTER" -- Patches/ Resources/)
declare -A ASSET_FORMULAE=()
declare -A ASSET_CHANGED=()   # formula -> the changed asset files that map to it, one per line
for f in "${ASSET_FILES[@]}"; do
  IFS=/ read -r top first second _ <<< "$f"
  if [[ "$top" == Resources && "$first" == _shared && -n "$second" ]]; then
    while IFS= read -r rb; do
      ASSET_FORMULAE[$(basename "$rb" .rb)]=1
      ASSET_CHANGED[$(basename "$rb" .rb)]+="$f"$'\n'
    done < <(grep -rlF "\"Resources/_shared/$second" Formula/ 2>/dev/null || true)
  elif [[ -n "$first" && "$first" != _shared ]]; then
    for rb in Formula/*/"$first".rb; do
      if [ -f "$rb" ]; then
        ASSET_FORMULAE[$first]=1
        ASSET_CHANGED[$first]+="$f"$'\n'
      fi
    done
  fi
done

# True when formula $1's last commit (as of $AFTER) is a bottle write-back and
# every changed asset file's last commit is an ancestor of it. The write-back
# is made from the branch head the build ran on, so its bottle already
# contains those asset changes. Without this, a merged PR that changed
# Resources/<f>/ was rebuilt after the merge even though pr-validate had just
# built and published it: a redundant release, plus a bot PR that rewrote the
# bottle block and conflicted with every PR still open on the same formula.
# An asset commit that is not an ancestor (changed after the write-back, or
# landed on the base branch and was never part of that build) still rebuilds.
bottled_since_assets() {
  local name="$1" rb last_rb f c
  rb=$(compgen -G "Formula/*/$name.rb" | head -n 1) || return 1
  [ -n "$rb" ] || return 1
  last_rb=$(git log -1 --format=%H "$AFTER" -- "$rb")
  [ -n "$last_rb" ] || return 1
  [[ "$(git log -1 --format=%s "$last_rb")" =~ $BOTTLE_COMMIT_RE ]] || return 1
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    c=$(git log -1 --format=%H "$AFTER" -- "$f")
    [ -n "$c" ] || return 1
    git merge-base --is-ancestor "$c" "$last_rb" || return 1
  done <<< "${ASSET_CHANGED[$name]:-}"
  return 0
}
for name in "${!ASSET_FORMULAE[@]}"; do
  [[ "$name" =~ ^[A-Za-z0-9@+._-]+$ ]] \
    || { echo "::error::invalid formula name: $name"; exit 1; }
  # `git diff` against a formula already built above would duplicate it.
  if ! printf '%s\n' "${CHANGED[@]:-}" | grep -qx "$name"; then CHANGED+=("$name"); fi
  if printf '%s\n' "${BUILD[@]:-}" "${HEAVY[@]:-}" | grep -qx "$name"; then continue; fi
  if bottled_since_assets "$name"; then
    echo "::notice::$name: Patches/Resources changed, but its last commit is a bottle write-back that contains them, skipping build"
    continue
  fi
  echo "::notice::$name: Patches/Resources changed, rebuilding"
  if tr ' ' '\n' <<< "$HEAVY_FORMULAS" | grep -qx "$name"; then
    HEAVY+=("$name")
  else
    BUILD+=("$name")
  fi
done

{
  echo "build=$(jq -cn '$ARGS.positional' --args "${BUILD[@]}")"
  echo "changed=$(jq -cn '$ARGS.positional' --args "${CHANGED[@]}")"
  echo "heavy=$(jq -cn '$ARGS.positional' --args "${HEAVY[@]}")"
} >> "$GITHUB_OUTPUT"

{
  echo "### detect-changes"
  echo "- build: ${BUILD[*]:-(none)}"
  echo "- heavy (light-check only): ${HEAVY[*]:-(none)}"
} >> "$GITHUB_STEP_SUMMARY"
