#!/usr/bin/env python3
"""Declare the screen-capture and network permissions in the HAP's module.json.

QAbility requests ohos.permission.CUSTOM_SCREEN_CAPTURE at runtime, and QtNetwork
needs INTERNET for translation requests. The Qt template leaves requestPermissions
empty, so capture fails with PermissionDenied and HTTPS requests cannot resolve
their hosts. GET_NETWORK_INFO lets the app inspect connectivity before requests.
"""
import json
import os
from pathlib import Path
import sys
import zipfile

PERMISSIONS = (
    ('ohos.permission.CUSTOM_SCREEN_CAPTURE',
     'Capture the screen for screenshots and annotations'),
    ('ohos.permission.INTERNET', 'Send text translation requests'),
    ('ohos.permission.GET_NETWORK_INFO', 'Check network availability for translation'),
)
MODULE_NAME = 'module.json'


def add_permission(hap):
    hap = Path(hap)
    with zipfile.ZipFile(hap) as source:
        manifest = json.loads(source.read(MODULE_NAME))
        module = manifest['module']
        permissions = module.setdefault('requestPermissions', [])
        for permission, reason in PERMISSIONS:
            if not any(item.get('name') == permission for item in permissions):
                permissions.append({
                    'name': permission,
                    'reason': reason,
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
