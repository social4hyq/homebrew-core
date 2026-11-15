#!/bin/sh
set -eu

: "${SNOW_SHOT_HAP:?snow-shot-install: SNOW_SHOT_HAP is not configured}"

for option in "$@"; do
  case "$option" in
    --hap|--hap=*|--bundle-id|--bundle-id=*|--app-name|--app-name=*|--module|--module=*|--ability|--ability=*)
      printf 'snow-shot-install: %s is fixed by this formula\n' "$option" >&2
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
