#!/usr/bin/env bash
# obsidian: run an Obsidian CLI command against the running desktop app.
# Bare entry point matching https://obsidian.md/cli; management of the HAP
# itself (install/start/stop/status/uninstall) stays in `obsidian-app`.
set -euo pipefail

exec "${OBSIDIAN_DESKTOP_NODE:-node}" \
  "${OBSIDIAN_DESKTOP_CLI:?missing CLI client}" "$@"
