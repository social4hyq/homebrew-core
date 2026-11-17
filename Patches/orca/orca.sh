#!/bin/sh
# orca: Orca's runtime server and CLI on HarmonyOS.
#
# Upstream `orca serve` asks the installed desktop app which server runtime to
# use, and that selection has no openharmony target. On this platform serve maps
# to the runtime server built here; every other command is the upstream CLI,
# which talks to a running server over the same profile.
set -e

root="${ORCA_ROOT:?ORCA_ROOT is not set}"

case "${1:-}" in
  serve)
    shift
    exec node "$root/orcad/orcad-server.js" --bind 127.0.0.1 --web-client-root "$root/orcad/web" "$@"
    ;;
esac

exec node "$root/orcad/out/cli/index.js" "$@"
