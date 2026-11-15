#!/bin/sh
set -eu

: "${SNOW_SHOT_HAP:?snow-shot: SNOW_SHOT_HAP is not configured}"

usage() {
  cat <<'EOF'
Usage: snow-shot <command> [options]

  install [--no-start] [--device <id>] [--project-dir <path>] [--signed-hap <path>]
                sign the bottled HAP with a local debug profile, install it on
                a connected device and start it
  help          show this help
EOF
}

install_hap() {
  for option in "$@"; do
    case "$option" in
      --hap|--hap=*|--bundle-id|--bundle-id=*|--app-name|--app-name=*|--module|--module=*|--ability|--ability=*)
        printf 'snow-shot: %s is fixed by this formula\n' "$option" >&2
        exit 2
        ;;
    esac
  done

  # HarmonyOS PC hdc servers can start without connecting to their own local
  # device. Use the bundled hdc and the advertised persist.hdc.port to attach
  # it before hap-installer asks the DevEco CLI for connected devices.
  hdc="${SNOW_SHOT_HDC:-hdc}"
  if ! "$hdc" list targets 2>/dev/null | grep -q '127\.0\.0\.1:'; then
    port="$(param get persist.hdc.port 2>/dev/null | tr -d '[:space:]' || true)"
    if [ -n "$port" ]; then
      "$hdc" tconn "127.0.0.1:$port" >/dev/null 2>&1 || true
    fi
  fi

  exec hap-installer \
    --hap "$SNOW_SHOT_HAP" \
    --bundle-id com.social4hyq.snowshot \
    --app-name SnowShot \
    --module entry \
    --ability QAbility \
    "$@"
}

case "${1:-help}" in
  -h|--help|help)
    usage
    ;;
  install)
    shift
    install_hap "$@"
    ;;
  *)
    printf 'snow-shot: unknown command: %s\n' "$1" >&2
    usage >&2
    exit 2
    ;;
esac
