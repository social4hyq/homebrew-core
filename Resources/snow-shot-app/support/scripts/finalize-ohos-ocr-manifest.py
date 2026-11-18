#!/usr/bin/env python3
"""Bind the OCR manifest to the final runtime bytes after HAP native stripping."""
import hashlib
import json
import os
from pathlib import Path
import sys
import zipfile


def finalize(hap):
    hap = Path(hap)
    manifest_name = 'resources/rawfile/ocr/asset-manifest.json'
    with zipfile.ZipFile(hap) as source:
        runtime = source.read('libs/arm64-v8a/libsnow_ocr_inprocess.so')
        manifest = json.loads(source.read(manifest_name))
        descriptor, = manifest['runtime']['files']
        runtime_name = 'libsnow_ocr_inprocess.so'
        if (descriptor['name'] != runtime_name or
                manifest['runtime']['executable'] != runtime_name):
            raise ValueError('OCR manifest does not describe the in-process runtime')
        descriptor.update(size=len(runtime), sha256=hashlib.sha256(runtime).hexdigest())
        temporary = hap.with_suffix('.finalizing.hap')
        try:
            with zipfile.ZipFile(temporary, 'w') as target:
                for info in source.infolist():
                    data = (json.dumps(manifest, ensure_ascii=False, separators=(',', ':')).encode()
                            if info.filename == manifest_name else source.read(info))
                    target.writestr(info, data)
            os.replace(temporary, hap)
        finally:
            temporary.unlink(missing_ok=True)


if __name__ == '__main__':
    finalize(sys.argv[1])
