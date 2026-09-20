# Shared helpers for CI scripts (sourced, not executed)
set -euo pipefail

: "${CONTAINER:=ohos}"
: "${BREW_ENV:=HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_ENV_HINTS=1}"

TAP=social4hyq/core

# Run a shell command inside the OHOS container
cexec() { docker exec "$CONTAINER" bash -lc "$*"; }

# Run brew inside the container with the standard env
cbrew() { cexec "$BREW_ENV brew $*"; }
