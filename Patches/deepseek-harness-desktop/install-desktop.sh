#!/bin/sh
# Install the prebuilt unsigned DeepSeek Harness desktop HAP through hap-installer.
# Signing material stays in the user's home directory; the HAP in the bottle is unsigned.
set -eu

HAP="${DSH_DESKTOP_UNSIGNED_HAP:?DSH_DESKTOP_UNSIGNED_HAP is required}"
exec hap-installer --hap "$HAP" \
  --bundle-id com.huawei.ohos_electron \
  --app-name DeepSeekHarnessSigning \
  --module electron \
  --ability EntryAbility
