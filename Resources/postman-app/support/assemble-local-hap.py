#!/usr/bin/env python3
"""Assemble an unsigned Postman HAP locally from a verified official tar.gz.

The bottle ships only a tap-authored Electron-OHOS shell. At install time we
download Postman's official linux-arm64 tarball, verify its SHA-256, and inject
its unpacked app tree into a copy of the shell HAP. Native glibc addons that
cannot load on OHOS/musl are trimmed (documented feature trade-offs); the rest
of the app is JavaScript and runs in the Electron-OHOS runtime.
"""
import argparse
import hashlib
import json
import os
import shutil
import tarfile
import tempfile
import zipfile
from pathlib import Path, PurePosixPath

APP_BUNDLE_ID = 'com.social4hyq.postman'
VENDOR_ROOT = 'Postman/app/resources/app/'
HAP = 'resources/resfile/resources/'
APP_ROOT = HAP + 'app/'
WORK = Path(__file__).resolve().parent
FUSE_SENTINEL = b'dL7pKGdnNz796PbbjQWNKmHXBZaB9tsX'
ELECTRON_LIB = 'libs/arm64-v8a/libelectron.so'

# Native glibc ELFs that cannot be dlopen'd/exec'd by the OHOS/musl Electron
# runtime. Trimming them disables the corresponding features but keeps the core
# API client usable. Each entry is a path relative to VENDOR_ROOT.
TRIMMED_NATIVE = {
    'node_modules/native_modules/build/Release/keytar.node',
    'node_modules/native_modules/build/Release/bufferutil.node',
    'node_modules/native_modules/build/Release/validation.node',
    'node_modules/native_modules/build/Release/pty.node',
    'node_modules/native_modules/watcher.node',
    'node_modules/native_modules/prebuilds/linux-arm64/node.napi.glibc.node',
    'node_modules/native_modules/prebuilds/linux-arm64/node.napi.glibc1.node',
    'node_modules/native_modules/rg',
}
# Files we require to be present after trimming.
REQUIRED = {'main.js', 'package.json', 'assets/icon.png'}
# Max uncompressed size of a single app member (guards against tar bombs).
MAX_MEMBER = 64 * 1024 * 1024


def vendor_pin():
    """The pinned vendor version and sha256, from the formula's vendor.json."""
    with open(os.environ['POSTMAN_APP_VENDOR_JSON'], encoding='utf-8') as stream:
        pin = json.load(stream)
    return pin['version'], pin['sha256']


def checked_sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def read_app_version(stage):
    with (stage/'package.json').open(encoding='utf-8') as stream:
        return json.load(stream).get('version')


def selected_payload(tarball, stage):
    """Verify the tarball and extract the trimmed Postman app tree to stage/."""
    version, sha256 = vendor_pin()
    if checked_sha(tarball) != sha256:
        raise ValueError(f'vendor package SHA-256 mismatch for Postman {version}')
    count = 0
    with tarfile.open(tarball, mode='r:gz') as archive:
        for member in archive:
            name = member.name
            if not name.startswith(VENDOR_ROOT):
                continue
            rel = name[len(VENDOR_ROOT):]
            if not rel or rel in TRIMMED_NATIVE:
                continue
            parts = PurePosixPath(rel).parts
            if '..' in parts or rel.startswith('/'):
                raise ValueError(f'invalid vendor member path: {rel}')
            if not member.isfile():
                continue
            if member.size > MAX_MEMBER:
                raise ValueError(f'vendor member too large: {rel}')
            target = stage/rel
            target.parent.mkdir(parents=True, exist_ok=True)
            with archive.extractfile(member) as inp, target.open('wb') as out:
                shutil.copyfileobj(inp, out)
            count += 1
    missing = {name for name in REQUIRED if not (stage/name).is_file()}
    if missing:
        raise ValueError(f'incomplete Postman payload, missing: {sorted(missing)}')
    actual = read_app_version(stage)
    if actual != version:
        raise ValueError(f'unexpected Postman version: {actual} (pinned {version})')
    return count


def require_cookie_encryption(shell):
    with zipfile.ZipFile(shell) as z, z.open(ELECTRON_LIB) as lib:
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


def assemble(shell, tarball, output):
    require_cookie_encryption(shell)
    with tempfile.TemporaryDirectory(prefix='postman-payload-') as temp:
        stage = Path(temp)
        selected_payload(tarball, stage)
        with zipfile.ZipFile(shell) as src:
            entries = src.namelist()
            if ('module.json' not in entries or len(set(entries)) != len(entries)
                    or any(n.startswith(APP_ROOT+'vendor/') or n == APP_ROOT+'vendor.asar'
                           for n in entries)):
                raise ValueError('expected a shell-only HAP with no vendor payload')
            module = json.loads(src.read('module.json'))
            if module['app']['bundleName'] != APP_BUNDLE_ID:
                raise ValueError(f'expected Postman bundle {APP_BUNDLE_ID}')
            with output.open('xb') as out, zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as dst:
                for entry in src.infolist():
                    # Drop the shell's placeholder app dir; we write the real one.
                    if entry.filename.startswith(APP_ROOT):
                        continue
                    with src.open(entry) as inp, dst.open(entry, 'w') as target:
                        shutil.copyfileobj(inp, target)
                # The Electron entry is our bootstrap, which loads the vendor main.
                wrapper = {"name": "postman-ohos-shell", "productName": "Postman",
                           "version": vendor_pin()[0], "main": "postman-bootstrap.cjs"}
                dst.writestr(APP_ROOT+'package.json', json.dumps(wrapper))
                dst.write(WORK/'postman-bootstrap.cjs', APP_ROOT+'postman-bootstrap.cjs')
                # Inject the trimmed vendor app tree under app/vendor/.
                for path in sorted(stage.rglob('*')):
                    if not path.is_file():
                        continue
                    rel = path.relative_to(stage).as_posix()
                    info = zipfile.ZipInfo(APP_ROOT+'vendor/'+rel)
                    info.create_system = 3
                    info.external_attr = 0o100000 << 16
                    info.compress_type = zipfile.ZIP_DEFLATED
                    with path.open('rb') as inp, dst.open(info, 'w') as out:
                        shutil.copyfileobj(inp, out)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    for arg in ('shell', 'tarball', 'output'):
        parser.add_argument(arg, type=Path)
    a = parser.parse_args()
    if a.output.exists():
        parser.error('output already exists')
    assemble(a.shell.resolve(), a.tarball.resolve(), a.output.resolve())
