#!/usr/bin/env python3
"""Assemble an unsigned Claude Desktop HAP locally from a verified vendor .deb."""
import argparse
import hashlib
import json
import shutil
import struct
import subprocess
import tarfile
import tempfile
import zipfile
from pathlib import Path, PurePosixPath

VERSION = '5.11492.5'
APP_BUNDLE_ID = 'com.social4hyq.claudecode'
DEB_SHA256 = 'fe6cd8a70f96b96eb4e6b647300cfaee6aaff4ce133a0fbbe11c2cdb775f5a6a'
VENDOR = 'usr/lib/claude-desktop/resources/'
HAP = 'resources/resfile/resources/'
ASSETS = {'app.asar', 'ion-dist.asar', 'icon.png', 'TrayIconLinux.png', 'TrayIconLinux-Dark.png'}
WORK = Path(__file__).resolve().parent
FUSE_SENTINEL = b'dL7pKGdnNz796PbbjQWNKmHXBZaB9tsX'
ELECTRON_LIB = 'libs/arm64-v8a/libelectron.so'


def checked_sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def selected_payload(deb, stage):
    if checked_sha(deb) != DEB_SHA256:
        raise ValueError(f'vendor package SHA-256 mismatch for Claude {VERSION}')
    selected = {}
    with subprocess.Popen(['ar', 'p', str(deb), 'data.tar.xz'], stdout=subprocess.PIPE) as ar:
        with tarfile.open(fileobj=ar.stdout, mode='r|xz') as archive:
            for member in archive:
                name = member.name.removeprefix('./')
                if not name.startswith(VENDOR):
                    continue
                rel = name[len(VENDOR):]
                if rel not in ASSETS and not rel.startswith('app.asar.unpacked/'):
                    continue
                if not member.isfile():
                    continue
                parts = PurePosixPath(rel).parts
                if '..' in parts or rel.startswith('/') or rel in selected:
                    raise ValueError(f'invalid or duplicate vendor member: {rel}')
                target = stage / str(len(selected))
                with archive.extractfile(member) as inp, target.open('wb') as out:
                    shutil.copyfileobj(inp, out)
                selected[rel] = (target, member.mode)
        while ar.stdout.read(128 * 1024):
            pass
        if ar.wait():
            raise RuntimeError('failed to read Debian data archive')
    if not ASSETS.issubset(selected):
        raise ValueError('incomplete Claude desktop payload')
    if not any(n.startswith('app.asar.unpacked/') for n in selected):
        raise ValueError('missing Claude unpacked resources')
    return selected


def read_app_package(archive):
    with archive.open('rb') as f:
        marker, offset, _, n = struct.unpack('<4I', f.read(16))
        if marker != 4 or not 0 < n <= min(offset, 16 * 1024 * 1024):
            raise ValueError('invalid Claude ASAR index')
        header = json.loads(f.read(n))
        pkg = header['files']['package.json']
        f.seek(8 + offset + int(pkg['offset']))
        data = json.loads(f.read(int(pkg['size'])))
    if data.get('version') != VERSION or data.get('main') != '.vite/build/index.pre.js':
        raise ValueError('unexpected Claude version or entry')
    data['main'] = 'bootstrap.cjs'
    return data


def require_cookie_encryption(shell):
    with zipfile.ZipFile(shell) as z, z.open(ELECTRON_LIB) as lib:
        # Read through the fuse wire, not the entire large ELF into memory.
        tail = b''
        while chunk := lib.read(1024 * 1024):
            buf = tail + chunk
            idx = buf.find(FUSE_SENTINEL)
            if idx != -1:
                start = idx + len(FUSE_SENTINEL)
                header = (buf[start:start + 4] + lib.read(max(0, start + 4 - len(buf))))[:4]
                if len(header) == 4 and header[0] == 1 and header[1] >= 2 and header[3] == ord('1'):
                    return
                break
            tail = buf[-(len(FUSE_SENTINEL)-1):]
    raise ValueError('shell does not enable Electron cookie encryption')


def assemble(shell, deb, output):
    require_cookie_encryption(shell)
    with tempfile.TemporaryDirectory(prefix='claude-payload-') as temp:
        selected = selected_payload(deb, Path(temp))
        package = read_app_package(selected['app.asar'][0])
        with zipfile.ZipFile(shell) as src:
            entries = src.namelist()
            if ('module.json' not in entries or len(set(entries)) != len(entries)
                or any(n.startswith((HAP+'app.asar', HAP+'app/vendor.asar')) or
                       n == HAP+'ion-dist.asar' for n in entries)):
                raise ValueError('expected a shell-only HAP with no vendor payload')
            module = json.loads(src.read('module.json'))
            if module['app']['bundleName'] != APP_BUNDLE_ID:
                raise ValueError(f'expected Claude Code bundle {APP_BUNDLE_ID}')
            with output.open('xb') as out, zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as dst:
                for entry in src.infolist():
                    if entry.filename.startswith(HAP+'app/') or entry.filename in {HAP+n for n in ASSETS}:
                        continue
                    with src.open(entry) as inp, dst.open(entry, 'w') as target:
                        shutil.copyfileobj(inp, target)
                dst.writestr(HAP+'app/package.json', json.dumps(package))
                for name, source in [('bootstrap.cjs', 'claude-bootstrap.cjs'),
                                     ('claude-launch-bridge.cjs', 'claude-launch-bridge.cjs'),
                                     ('claude-ohos-config.cjs', 'claude-ohos-config.cjs'),
                                     ('claude-code-platform-patch.cjs', 'claude-code-platform-patch.cjs')]:
                    dst.write(WORK/source, HAP+'app/'+name)
                for name, (file, mode) in selected.items():
                    target = 'app/vendor'+name[3:] if name.startswith('app.asar') else name
                    info = zipfile.ZipInfo(HAP+target)
                    info.create_system = 3
                    info.external_attr = (0o100000 | mode) << 16
                    info.compress_type = zipfile.ZIP_DEFLATED
                    with file.open('rb') as inp, dst.open(info, 'w') as out:
                        shutil.copyfileobj(inp, out)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    for arg in ('shell', 'deb', 'output'):
        parser.add_argument(arg, type=Path)
    a = parser.parse_args()
    if a.output.exists():
        parser.error('output already exists')
    assemble(a.shell.resolve(), a.deb.resolve(), a.output.resolve())
