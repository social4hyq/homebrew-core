#!/bin/bash
# Classify formulae changed between $BEFORE and $AFTER into build / heavy /
# changed lists (JSON arrays written to $GITHUB_OUTPUT). Bottle-block-only
# changes are skipped; names in $HEAVY_FORMULAS get light checks only.
set -euo pipefail

if [[ "$BEFORE" =~ ^0+$ ]] || ! git cat-file -e "$BEFORE" 2>/dev/null; then
  echo "::warning::event.before unavailable (new branch/force push), comparing HEAD^..HEAD"
  BEFORE=$(git rev-parse "$AFTER^")
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
     diff <(git show "$BEFORE:$f" | strip_bottle | strip_comments) \
          <(git show "$AFTER:$f"  | strip_bottle | strip_comments) >/dev/null; then
    echo "::notice::$name: comment only, skipping build"
    continue
  fi
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
