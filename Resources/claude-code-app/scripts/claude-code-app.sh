#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: claude-code-app install [--no-acl] [--device HDC_TARGET]
       claude-code-app start [--device HDC_TARGET]
       claude-code-app --help

`install` signs and installs the local HAP. `start` opens the installed app.
EOF
}

case "${1:-}" in
  --help|-h|help)
    usage
    ;;
  install)
    shift
    tmp_parent="${TMPDIR:-/data/storage/el2/base/cache}"
    mkdir -p -- "$tmp_parent"
    work=$(mktemp -d "$tmp_parent/claude-code-app.XXXXXX")
    trap 'rm -rf -- "$work"' EXIT
    "$CLAUDE_CODE_APP_INSTALL_SCRIPT" "$CLAUDE_CODE_APP_UNSIGNED_HAP" "$work" "$@"
    ;;
  start)
    shift
    device=()
    if [[ "${1:-}" == --device ]]; then
      [[ $# -ge 2 ]] || { echo "--device requires a target" >&2; exit 2; }
      device=(-t "$2")
      shift 2
    fi
    [[ $# == 0 ]] || { usage >&2; exit 2; }
    exec "$CLAUDE_CODE_APP_HDC" "${device[@]}" shell aa start \
      -a EntryAbility -b com.social4hyq.claudecode -m electron
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
