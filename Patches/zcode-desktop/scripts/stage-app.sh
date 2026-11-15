#!/usr/bin/env bash
# Stage the shell app and ZCode branding into the local ohos_hap project.
# Mirrors what the tap formula does at build time (electron-ohos 37 template).
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHELL_DIR="$PROJECT_DIR/libelectron/ohos_hap"
APP_SRC="$PROJECT_DIR/app"
BUNDLE_NAME="com.social4hyq.zcodedesktop"
APP_NAME="ZCode"

[ -d "$SHELL_DIR" ] || {
  printf 'missing %s; unpack the electron-ohos 37 prebuilt first:\n' "$SHELL_DIR" >&2
  printf '  unzip -d . v37.2.1-openharmony-arm64.zip && tar -xzf libelectron_138.tar.gz\n' >&2
  exit 1
}

APP_DST="$SHELL_DIR/web_engine/src/main/resources/resfile/resources/app"
rm -rf "$APP_DST"
mkdir -p "$APP_DST"
cp "$APP_SRC"/main.cjs "$APP_SRC"/package.json "$APP_SRC"/config.json "$APP_SRC"/waiting.html "$APP_DST/"

cp "$PROJECT_DIR/assets/icon.png" "$SHELL_DIR/AppScope/resources/base/media/app_icon.png"
cp "$PROJECT_DIR/assets/icon.png" "$SHELL_DIR/AppScope/resources/base/media/startIcon.png"

python3 - "$SHELL_DIR" "$BUNDLE_NAME" "$APP_NAME" <<'PY'
import glob, json, re, sys

shell, bundle, app_name = sys.argv[1], sys.argv[2], sys.argv[3]

app_json5 = f"{shell}/AppScope/app.json5"
s = open(app_json5).read()
s = s.replace('"bundleName": "com.huawei.ohos_electron"', f'"bundleName": "{bundle}"')
s = s.replace('"vendor": "example"', '"vendor": "social4hyq"')
open(app_json5, "w").write(s)

for path in glob.glob(f"{shell}/AppScope/resources/*/element/string.json") + \
            glob.glob(f"{shell}/electron/src/main/resources/*/element/string.json"):
    strings = json.load(open(path))
    for entry in strings["string"]:
        if entry["name"] in ("app_name", "EntryAbility_label"):
            entry["value"] = app_name
    with open(path, "w") as fh:
        json.dump(strings, fh, indent=2, ensure_ascii=False)
        fh.write("\n")

# electron-ohos 37 template: drop the product signingConfig and the embedded
# signingConfigs block, and pin the SDK target the build toolchain supports.
profile = json.load(open(f"{shell}/build-profile.json5"))
for product in profile["app"]["products"]:
    product.pop("signingConfig", None)
    product["compatibleSdkVersion"] = "6.0.0(20)"
profile["app"].pop("signingConfigs", None)
with open(f"{shell}/build-profile.json5", "w") as fh:
    json.dump(profile, fh, indent=2)
    fh.write("\n")

electron_module = f"{shell}/electron/src/main/module.json5"
s = open(electron_module).read()
if '"extractNativeLibs": true' not in s:
    s = s.replace('"mainElement": "EntryAbility",',
                  '"mainElement": "EntryAbility",\n    "extractNativeLibs": true,', 1)
    open(electron_module, "w").write(s)

web_engine = f"{shell}/web_engine/src/main/module.json5"
s = open(web_engine).read()
s, n = re.subn(r'"requestPermissions": \[.*?\n    \],',
               '"requestPermissions": [\n'
               '      { "name": "ohos.permission.INTERNET" },\n'
               '      { "name": "ohos.permission.GET_NETWORK_INFO" }\n'
               '    ],', s, count=1, flags=re.S)
if n != 1:
    raise SystemExit("requestPermissions block not found in web_engine module.json5")
open(web_engine, "w").write(s)
PY

printf 'staged %s into %s\n' "$APP_NAME" "$APP_DST"
