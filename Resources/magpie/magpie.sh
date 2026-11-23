#!/bin/sh
# Entry point of bin/magpie. `magpie web` goes through magpie-web.js, which records
# where the page listens and its key so the Magpie desktop app can open the same
# page; everything else is the real binary, unchanged.
#   MAGPIE_REAL  the real magpie binary (set by the formula)
#   MAGPIE_BUN   the bun that runs magpie-web.js (set by the formula)
here=$(cd "$(dirname "$0")" && pwd)
if [ "${1:-}" = web ]; then
  exec "${MAGPIE_BUN:?}" "$here/magpie-web.js" "$@"
fi
exec "${MAGPIE_REAL:?}" "$@"
