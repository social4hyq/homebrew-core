#!/usr/bin/env bash
# Stage the host-authored, vendor-free Postman shell from Electron OHOS 40.
set -euo pipefail
[[ $# == 2 ]] || { echo "usage: $0 ELECTRON_OHOS_TEMPLATE NEW_PROJECT_DIR" >&2; exit 2; }
tools=$(cd -- "$(dirname -- "$0")" && pwd)
template=$(cd -- "$1" && pwd)
dest=$2
icon_file="$tools/../assets/icon.png"
[[ -f "$icon_file" ]] || { echo "missing icon: $icon_file" >&2; exit 2; }
[[ ! -e $dest ]] || { echo "destination already exists: $dest" >&2; exit 2; }
[[ -f "$template/AppScope/app.json5" && -f "$template/electron/libs/arm64-v8a/libelectron.so" ]] || {
  echo 'invalid Electron OHOS template' >&2; exit 2;
}
mkdir -- "$dest"
cp -a "$template/." "$dest"
python3 - "$dest" <<'PY'
import json
import os
import re
import shutil
import sys
from pathlib import Path

root = Path(sys.argv[1])
version = os.environ.get('POSTMAN_APP_VERSION', '12.38.0')
match = re.fullmatch(r'([1-9][0-9]*)\.([0-9]+)\.([0-9]+)', version)
if not match:
    raise ValueError(f'invalid Postman version: {version}')
major, minor, patch = (int(part) for part in match.groups())
# versionCode: major 2 digits | minor 4 digits | patch 5 digits, /100, within int32
digits = f'{major:02d}{minor:04d}{patch:05d}'
version_code = int(digits) // 100
if version_code > 2_147_483_647:
    raise ValueError(f'Postman version exceeds app versionCode: {version}')

def edit(rel, fn):
    p = root / rel
    p.write_text(fn(p.read_text()))

def replace_one(s, old, new):
    if s.count(old) != 1:
        raise ValueError(f'expected one template field: {old}')
    return s.replace(old, new)

bundle_id = 'com.social4hyq.postman'
app_name = 'Postman'
edit('AppScope/app.json5', lambda s: replace_one(s, 'com.huawei.ohos_electron', bundle_id))
edit('AppScope/app.json5', lambda s: replace_one(s, '"vendor": "example"', '"vendor": "social4hyq"'))
edit('AppScope/app.json5', lambda s: replace_one(s, '"versionCode": 1000001', f'"versionCode": {version_code}'))
edit('AppScope/app.json5', lambda s: replace_one(s, '"versionName": "1.0.1"', f'"versionName": "{version}"'))
edit('build-profile.json5', lambda s: re.sub(r'^\s*"signingConfig": "default",\n', '\n', s, flags=re.M))
edit('electron/src/main/module.json5',
     lambda s: replace_one(s, '"mainElement": "EntryAbility",',
                           '"mainElement": "EntryAbility",\n    "extractNativeLibs": true,'))
# Postman runs under the weak sandbox: it reads/writes the host home and execs
# host CLI binaries (ripgrep, node workers, dataset engine). Declare the ACL
# permissions so app-installer's ACL variant can be granted by a debug profile.
def permission(s):
    s, n = re.subn(r'"requestPermissions": \[.*?\n    \]',
                   '"requestPermissions": ['
                   '{"name":"ohos.permission.INTERNET"},'
                   '{"name":"ohos.permission.GET_NETWORK_INFO"},'
                   '{"name":"ohos.permission.CUSTOM_SANDBOX"},'
                   '{"name":"ohos.permission.READ_WRITE_USER_FILE"}]', s, flags=re.S)
    if n != 1:
        raise ValueError('expected one requestPermissions in web_engine template')
    return s
edit('web_engine/src/main/module.json5', permission)
for top in ('AppScope', 'electron/src/main'):
    for p in (root/top/'resources').glob('*/element/string.json'):
        data = json.loads(p.read_text())
        changed = False
        for item in data.get('string', []):
            if item['name'] in ('app_name', 'EntryAbility_label'):
                item['value'] = app_name
                changed = True
        if changed:
            p.write_text(json.dumps(data))
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
edit('web_engine/src/main/ets/ability/WebAbility.ets',
     lambda s: replace_one(s, '    super.onWindowStageCreate(windowStage);\n', CLOSE_HANDLER))
app = root/'web_engine/src/main/resources/resfile/resources/app'
if app.exists():
    shutil.rmtree(app)
app.mkdir(parents=True)
(app/'package.json').write_text('{"name":"postman-ohos-shell","main":"shell.cjs"}\n')
(app/'shell.cjs').write_text("require('electron').app.exit(2);\n")
PY
for icon in app_icon.png icon.png; do
  cp "$icon_file" "$dest/AppScope/resources/base/media/$icon"
done
