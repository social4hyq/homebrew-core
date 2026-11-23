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
  echo "invalid Antigravity IDE version: $version" >&2; exit 2;
}
major=${BASH_REMATCH[1]}; minor=${BASH_REMATCH[2]}; patch=${BASH_REMATCH[3]}
printf -v version_digits '%02d%04d%05d' "$major" "$minor" "$patch"
version_code=$((10#$version_digits / 100))

cp -a "$template" "$dest"
python3 - "$dest" "$version" "$version_code" "$script_dir/../assets/icon.png" "$script_dir/../app/antigravity-ide-app-bootstrap.cjs" <<'PY'
import json
import re
import shutil
import sys
from pathlib import Path

root = Path(sys.argv[1])
version = sys.argv[2]
version_code = int(sys.argv[3])
icon = Path(sys.argv[4])
bootstrap = Path(sys.argv[5])

def replace_one(path, old, new):
    text = path.read_text()
    if text.count(old) != 1:
        raise ValueError(f"expected one {old!r} in {path}")
    path.write_text(text.replace(old, new))

app_json = root / "AppScope/app.json5"
replace_one(app_json, '"com.huawei.ohos_electron"', '"com.social4hyq.antigravityide"')
replace_one(app_json, '"vendor": "example"', '"vendor": "social4hyq"')
replace_one(app_json, '"versionCode": 1000001', f'"versionCode": {version_code}')
replace_one(app_json, '"versionName": "1.0.1"', f'"versionName": "{version}"')

profile = root / "build-profile.json5"
profile.write_text(re.sub(r'^\s*"signingConfig": "default",\n', "\n", profile.read_text(), flags=re.M))

module = root / "electron/src/main/module.json5"
text = module.read_text()
if '"scheme": "claude"' in text:
    text = text.replace('"scheme": "claude"', '"scheme": "antigravity"')
elif '"scheme": "link"' in text:
    text = text.replace('"scheme": "link"', '"scheme": "antigravity"')
elif '"scheme": "antigravity"' not in text:
    needle = '"scheme": "electron"'
    if text.count(needle) != 1:
        raise ValueError("could not register the antigravity: app link")
    text = text.replace(needle, needle + ',\n              {"scheme": "antigravity"}', 1)
module.write_text(text)

permissions = root / "web_engine/src/main/module.json5"
text = permissions.read_text()
text, count = re.subn(
    r'"requestPermissions": \[.*?\n    \]',
    '"requestPermissions": [{"name":"ohos.permission.INTERNET"},'
    '{"name":"ohos.permission.GET_NETWORK_INFO"}]',
    text, flags=re.S,
)
if count != 1:
    raise ValueError("could not set web_engine network permissions")
permissions.write_text(text)

for top in ("AppScope", "electron/src/main"):
    for path in (root / top / "resources").glob("*/element/string.json"):
        data = json.loads(path.read_text())
        for item in data.get("string", []):
            if item.get("name") in ("app_name", "EntryAbility_label"):
                item["value"] = "Antigravity IDE"
        path.write_text(json.dumps(data))

for name in ("app_icon.png", "icon.png"):
    shutil.copyfile(icon, root / "AppScope/resources/base/media" / name)

app = root / "web_engine/src/main/resources/resfile/resources/app"
if app.exists():
    shutil.rmtree(app)
app.mkdir(parents=True)
(app / "package.json").write_text(
    '{"name":"antigravity-ide-app-ohos-shell","productName":"Antigravity IDE",'
    f'"version":"{version}","main":"antigravity-ide-app-bootstrap.cjs"}}\n'
)
shutil.copyfile(bootstrap, app / "antigravity-ide-app-bootstrap.cjs")
PY
