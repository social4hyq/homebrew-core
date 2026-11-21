#!/usr/bin/env python3
"""Enable Electron's cookie-encryption fuse in an unsigned OHOS shell HAP."""
import argparse
import shutil
import zipfile
from pathlib import Path

SENTINEL = b'dL7pKGdnNz796PbbjQWNKmHXBZaB9tsX'
LIB = 'libs/arm64-v8a/libelectron.so'


def enable_cookie_encryption(data: bytes) -> bytearray:
    if data.count(SENTINEL) != 1:
        raise ValueError('expected exactly one Electron fuse wire')
    wire = data.index(SENTINEL) + len(SENTINEL)
    header = data[wire:wire + 2]
    if len(header) != 2 or header[0] != 1 or header[1] < 2:
        raise ValueError('unsupported Electron fuse wire')
    offset = wire + 3  # Cookie encryption is the second v1 fuse.
    if wire + 2 + header[1] > len(data) or data[offset] not in b'01':
        raise ValueError('invalid or removed cookie encryption fuse')
    updated = bytearray(data)
    updated[offset] = ord('1')
    return updated


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    with zipfile.ZipFile(args.source) as src:
        if src.namelist().count(LIB) != 1:
            raise ValueError(f'expected exactly one {LIB}')
        patched = enable_cookie_encryption(src.read(LIB))
        with args.output.open('xb') as stream, zipfile.ZipFile(stream, 'w') as dst:
            for entry in src.infolist():
                if entry.filename == LIB:
                    dst.writestr(entry, patched)
                else:
                    with src.open(entry) as inp, dst.open(entry, 'w') as out:
                        shutil.copyfileobj(inp, out)


if __name__ == '__main__':
    main()
