#!/usr/bin/env python3

import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

SCRIPT = Path(__file__).with_name('add-ohos-module-permissions.py')
SPEC = importlib.util.spec_from_file_location('add_ohos_module_permissions', SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class AddOhosModulePermissionsTest(unittest.TestCase):
    def test_network_and_capture_permissions_are_idempotent(self):
        with tempfile.TemporaryDirectory() as directory:
            hap = Path(directory) / 'entry.hap'
            manifest = {
                'module': {
                    'requestPermissions': [{
                        'name': 'ohos.permission.CUSTOM_SCREEN_CAPTURE',
                        'reason': 'Existing capture reason',
                        'usedScene': {'abilities': ['QAbility'], 'when': 'inuse'},
                    }],
                },
            }
            with zipfile.ZipFile(hap, 'w') as archive:
                archive.writestr('module.json', json.dumps(manifest))
                archive.writestr('libs/arm64-v8a/libsnow_shot.so', b'elf')

            MODULE.add_permission(hap)
            MODULE.add_permission(hap)

            with zipfile.ZipFile(hap) as archive:
                permissions = json.loads(archive.read('module.json'))['module']['requestPermissions']
                self.assertEqual(archive.read('libs/arm64-v8a/libsnow_shot.so'), b'elf')
            names = [item['name'] for item in permissions]
            self.assertEqual(names.count('ohos.permission.CUSTOM_SCREEN_CAPTURE'), 1)
            self.assertEqual(names.count('ohos.permission.INTERNET'), 1)
            self.assertEqual(names.count('ohos.permission.GET_NETWORK_INFO'), 1)
            self.assertEqual(permissions[0]['reason'], 'Existing capture reason')


if __name__ == '__main__':
    unittest.main()
