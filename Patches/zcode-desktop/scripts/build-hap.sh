#!/usr/bin/env bash
# Build the unsigned shell HAP locally from the working project.
# CI builds this in electron-ohos-ci; this helper is for device-side iteration.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHELL_DIR="$PROJECT_DIR/libelectron/ohos_hap"
DEVECO_CLI="${DEVECO_CLI:-$(command -v devecocli || true)}"

if [ -z "$DEVECO_CLI" ]; then
  printf 'devecocli not found; set DEVECO_CLI to the DevEco CLI entry point\n' >&2
  exit 1
fi

bash "$PROJECT_DIR/scripts/stage-app.sh"

mkdir -p "$PROJECT_DIR/logs"
cd "$SHELL_DIR"
node "$DEVECO_CLI" build > "$PROJECT_DIR/logs/build-hap.log" 2>&1 || {
  printf 'build failed, see %s\n' "$PROJECT_DIR/logs/build-hap.log" >&2
  exit 1
}

ls -la "$SHELL_DIR/electron/build/default/outputs/default/"
