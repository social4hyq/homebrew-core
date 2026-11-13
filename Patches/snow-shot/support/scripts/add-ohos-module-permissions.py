#!/usr/bin/env python3
"""Declare the screen-capture permission in the HAP's module.json.

QAbility requests ohos.permission.CUSTOM_SCREEN_CAPTURE at runtime, but the
Qt template's module.json leaves requestPermissions empty, so the system has
nothing to grant and every capture fails with PermissionDenied.
"""
import json
import os
from pathlib import Path
import sys
import zipfile

PERMISSION = 'ohos.permission.CUSTOM_SCREEN_CAPTURE'
MODULE_NAME = 'module.json'


def add_permission(hap):
    hap = Path(hap)
    with zipfile.ZipFile(hap) as source:
        manifest = json.loads(source.read(MODULE_NAME))
        module = manifest['module']
        permissions = module.setdefault('requestPermissions', [])
        if not any(item.get('name') == PERMISSION for item in permissions):
            permissions.append({
                'name': PERMISSION,
                'reason': 'Capture the screen for screenshots and annotations',
                'usedScene': {'abilities': ['QAbility'], 'when': 'inuse'},
            })
        data = json.dumps(manifest, ensure_ascii=False, separators=(',', ':')).encode()
        temporary = hap.with_suffix('.permissions.hap')
        try:
            with zipfile.ZipFile(temporary, 'w') as target:
                for info in source.infolist():
                    target.writestr(info, data if info.filename == MODULE_NAME else source.read(info))
            os.replace(temporary, hap)
        finally:
            temporary.unlink(missing_ok=True)


if __name__ == '__main__':
    add_permission(sys.argv[1])
