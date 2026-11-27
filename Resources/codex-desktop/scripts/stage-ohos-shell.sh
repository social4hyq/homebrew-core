#!/usr/bin/env bash
set -euo pipefail

[[ $# == 3 ]] || { echo "usage: $0 ELECTRON_OHOS_TEMPLATE DEST VERSION" >&2; exit 2; }
script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
template=$(cd -- "$1" && pwd)
dest=$2
version=$3
[[ ! -e "$dest" ]] || { echo "destination already exists: $dest" >&2; exit 2; }
[[ -f "$template/AppScope/app.json5" && -f "$template/electron/libs/arm64-v8a/libelectron.so" ]] || {
  echo "invalid Electron OHOS template" >&2; exit 2;
}
[[ "$version" =~ ^([1-9][0-9]*)\.([0-9]+)\.([0-9]+)$ ]] || {
  echo "invalid ChatGPT version: $version" >&2; exit 2;
}
major=${BASH_REMATCH[1]}; minor=${BASH_REMATCH[2]}; patch=${BASH_REMATCH[3]}
(( ${#major} <= 2 && ${#minor} <= 4 && ${#patch} <= 5 )) || {
  echo "ChatGPT version exceeds HAP versionCode component widths" >&2; exit 2;
}
printf -v version_digits '%02d%04d%05d' "$major" "$minor" "$patch"
version_code=$((10#$version_digits / 100))
(( version_code <= 2147483647 )) || { echo "HAP versionCode is out of range" >&2; exit 2; }

cp -a "$template" "$dest"
python3 - "$dest" "$version" "$version_code" "$script_dir/../assets/icon.png" <<'PY'
import json
import re
import shutil
import sys
from pathlib import Path

root = Path(sys.argv[1])
version = sys.argv[2]
version_code = int(sys.argv[3])
icon = Path(sys.argv[4])

def replace_one(path, old, new):
    text = path.read_text()
    if text.count(old) != 1:
        raise ValueError(f"expected one {old!r} in {path}")
    path.write_text(text.replace(old, new))

app_json = root / "AppScope/app.json5"
replace_one(app_json, '"com.huawei.ohos_electron"', '"com.social4hyq.chatgpt"')
replace_one(app_json, '"vendor": "example"', '"vendor": "social4hyq"')
replace_one(app_json, '"versionCode": 1000001', f'"versionCode": {version_code}')
replace_one(app_json, '"versionName": "1.0.1"', f'"versionName": "{version}"')

profile = root / "build-profile.json5"
profile.write_text(re.sub(r'^\s*"signingConfig": "default",\n', "\n", profile.read_text(), flags=re.M))

module = root / "electron/src/main/module.json5"
text = module.read_text()
if '"scheme": "claude"' in text:
    text = text.replace('"scheme": "claude"', '"scheme": "codex"')
elif '"scheme": "link"' in text:
    text = text.replace('"scheme": "link"', '"scheme": "codex"')
elif '"scheme": "codex"' not in text:
    needle = '"scheme": "electron"'
    if text.count(needle) != 1:
        raise ValueError("could not register the codex: app link")
    text = text.replace(needle, needle + ',\n              {"scheme": "codex"}', 1)
module.write_text(text)

permissions = root / "web_engine/src/main/module.json5"
text, count = re.subn(
    r'"requestPermissions": \[.*?\n    \]',
    '"requestPermissions": [{"name":"ohos.permission.INTERNET"},'
    '{"name":"ohos.permission.GET_NETWORK_INFO"}]',
    permissions.read_text(), flags=re.S,
)
if count != 1:
    raise ValueError("could not set web_engine network permissions")
permissions.write_text(text)

for top in ("AppScope", "electron/src/main"):
    for path in (root / top / "resources").glob("*/element/string.json"):
        data = json.loads(path.read_text())
        for item in data.get("string", []):
            if item.get("name") in ("app_name", "EntryAbility_label"):
                item["value"] = "ChatGPT"
        path.write_text(json.dumps(data))

for name in ("app_icon.png", "icon.png"):
    shutil.copyfile(icon, root / "AppScope/resources/base/media" / name)

# windowStageClose hides the ability and returns true, which tells the system not to
# close the window, so the window goes to the tray (owl-tray.cjs). Returning false
# lets the system close it right after the hide: the ability's session is destroyed
# and the whole app is killed. The tray's quit calls app.exit() to bypass this.
CLOSE_HANDLER = """    super.onWindowStageCreate(windowStage);
    try {
      windowStage.on('windowStageClose', () => {
        if (CheckEmptyUtils.isEmpty(this.xcomponentId)) {
          return false;
        }
        const widgetId = Number(this.xcomponentId.substring(ConfigData.WINDOW_PREFIX.length));
        Inject.getOrCreate(AppWindowAdapter).hideWindow(widgetId);
        return true;
      });
    } catch (exception) {
      LogUtil.error(TAG, 'Failed to register window close handler: ' + JSON.stringify(exception));
    }
"""
replace_one(root / "web_engine/src/main/ets/ability/WebAbility.ets",
            "    super.onWindowStageCreate(windowStage);\n", CLOSE_HANDLER)

app = root / "web_engine/src/main/resources/resfile/resources/app"
if app.exists():
    shutil.rmtree(app)
app.mkdir(parents=True)
(app / "package.json").write_text(
    '{"name":"chatgpt-ohos-shell","productName":"ChatGPT","main":"shell.cjs"}\n'
)
(app / "shell.cjs").write_text("require('electron').app.exit(2);\n")
PY
