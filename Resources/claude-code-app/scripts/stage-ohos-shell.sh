#!/usr/bin/env bash
# Stage the host-authored, vendor-free Claude Desktop shell from Electron 40.
set -euo pipefail
[[ $# == 2 ]] || { echo "usage: $0 ELECTRON_OHOS_TEMPLATE NEW_PROJECT_DIR" >&2; exit 2; }
tools=$(cd -- "$(dirname -- "$0")" && pwd)
template=$(cd -- "$1" && pwd)
dest=$2
icon_file="$tools/assets/claude-desktop.png"
[[ -f "$icon_file" ]] || icon_file="$tools/../assets/icon.png"
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
version = os.environ.get('CLAUDE_DESKTOP_APP_VERSION', '5.11492.5')
match = re.fullmatch(r'([1-9][0-9]*)\.([0-9]+)\.([0-9]+)', version)
if not match:
    raise ValueError(f'invalid Claude Desktop version: {version}')
major, minor, patch = (int(part) for part in match.groups())
# versionCode packing: major 6 bits | minor 17 bits | patch 8 bits, kept within
# the signed 32-bit HAP limit (63 << 25 | 131071 << 8 | 255 == 2**31 - 1).
# Claude Desktop's minor is a build counter that crossed the old 14-bit field
# (16_383) at 6.28899.2, so it now owns the wider middle field.
if major >= 64 or minor >= 131_072 or patch >= 256:
    raise ValueError(f'Claude Desktop version exceeds the app versionCode fields: {version}')
version_code = (major << 25) | (minor << 8) | patch
def edit(rel, fn):
    p = root / rel
    p.write_text(fn(p.read_text()))

def replace_one(s, old, new):
    if s.count(old) != 1:
        raise ValueError(f'expected one template field: {old}')
    return s.replace(old, new)

bundle_id = 'com.social4hyq.claudecode'
app_name = 'Claude Code'
edit('AppScope/app.json5', lambda s: replace_one(s, 'com.huawei.ohos_electron', bundle_id))
edit('AppScope/app.json5', lambda s: replace_one(s, '"vendor": "example"', '"vendor": "social4hyq"'))
edit('AppScope/app.json5', lambda s: replace_one(s, '"versionCode": 1000001', f'"versionCode": {version_code}'))
edit('AppScope/app.json5', lambda s: replace_one(s, '"versionName": "1.0.1"', f'"versionName": "{version}"'))
edit('build-profile.json5', lambda s: re.sub(r'^\s*"signingConfig": "default",\n', '\n', s, flags=re.M))
edit('electron/src/main/module.json5',
     lambda s: replace_one(replace_one(s, '"mainElement": "EntryAbility",',
             '"mainElement": "EntryAbility",\n    "extractNativeLibs": true,'),
             '"scheme": "link"', '"scheme": "claude"'))

def permission(s):
    s, n = re.subn(r'"requestPermissions": \[.*?\n    \]',
                   '"requestPermissions": [{"name":"ohos.permission.INTERNET"},'
                   '{"name":"ohos.permission.GET_NETWORK_INFO"}]', s, flags=re.S)
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
# windowStageClose hides the ability and returns true, which tells the system not to
# close the window, so the app stays resident behind the official app's own tray
# (its close handler hides the main window while the tray is enabled). Returning
# false lets the system close the window right after the hide: the ability's session
# is destroyed and the whole app ends, which is what the X button did.
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
(app/'package.json').write_text('{"name":"claude-ohos-shell","main":"shell.cjs"}\n')
(app/'shell.cjs').write_text("require('electron').app.exit(2);\n")
PY
for icon in app_icon.png icon.png; do
  cp "$icon_file" "$dest/AppScope/resources/base/media/$icon"
done
