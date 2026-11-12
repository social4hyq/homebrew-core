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

exec hap-installer \
  --hap "$SNOW_SHOT_HAP" \
  --bundle-id com.social4hyq.snowshot \
  --app-name SnowShot \
  --module entry \
  --ability QAbility \
  "$@"
