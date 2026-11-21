#!/usr/bin/env python3
"""Assemble an unsigned Claude Desktop HAP locally from a verified vendor .deb."""
import argparse
import hashlib
import io
import json
import os
import shutil
import struct
import tarfile
import tempfile
import zipfile
from pathlib import Path, PurePosixPath

APP_BUNDLE_ID = 'com.social4hyq.claudecode'
VENDOR = 'usr/lib/claude-desktop/resources/'
HAP = 'resources/resfile/resources/'
ASSETS = {'app.asar', 'ion-dist.asar', 'icon.png', 'TrayIconLinux.png', 'TrayIconLinux-Dark.png'}
WORK = Path(__file__).resolve().parent
FUSE_SENTINEL = b'dL7pKGdnNz796PbbjQWNKmHXBZaB9tsX'
ELECTRON_LIB = 'libs/arm64-v8a/libelectron.so'


def vendor_pin():
    """The pinned vendor version and sha256, from the formula's vendor.json."""
    with open(os.environ['CLAUDE_CODE_APP_VENDOR_JSON'], encoding='utf-8') as stream:
        pin = json.load(stream)
    return pin['version'], pin['sha256']


def checked_sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


class DebMemberReader(io.RawIOBase):
    """Read-only, seekable view over one ar-member byte range of a file."""

    def __init__(self, file, start, size):
        super().__init__()
        self._file = file
        self._start = start
        self._size = size
        self._pos = 0

    def readable(self):
        return True

    def seekable(self):
        return True

    def tell(self):
        return self._pos

    def seek(self, offset, whence=0):
        if whence == 0:
            target = offset
        elif whence == 1:
            target = self._pos + offset
        else:
            target = self._size + offset
        self._pos = max(0, min(target, self._size))
        return self._pos

    def readinto(self, b):
        want = min(len(b), self._size - self._pos)
        if want <= 0:
            return 0
        self._file.seek(self._start + self._pos)
        got = self._file.readinto(memoryview(b)[:want]) or 0
        self._pos += got
        return got

    def read(self, size=-1):
        if size < 0:
            size = self._size - self._pos
        buf = bytearray(size)
        return bytes(buf[:self.readinto(buf)])

    def close(self):
        if not self.closed:
            try:
                self._file.close()
            finally:
                super().close()


def deb_member(deb, member):
    """Stream one member of a Debian package (an ar archive) without binutils."""
    file = deb.open('rb')
    try:
        if file.read(8) != b'!<arch>\n':
            raise ValueError(f'{deb} is not a Debian package')
        while True:
            header = file.read(60)
            if len(header) < 60:
                raise ValueError(f'no {member} member in {deb}')
            name = header[:16].decode('ascii', 'replace').rstrip()
            if name.endswith('/'):
                name = name[:-1]
            size = int(header[48:58].decode('ascii').strip() or '0')
            if name == member:
                return DebMemberReader(file, file.tell(), size)
            file.seek(size + (size % 2), 1)
    except Exception:
        file.close()
        raise


def selected_payload(deb, stage):
    version, sha256 = vendor_pin()
    if checked_sha(deb) != sha256:
        raise ValueError(f'vendor package SHA-256 mismatch for Claude {version}')
    selected = {}
    with deb_member(deb, 'data.tar.xz') as stream:
        with tarfile.open(fileobj=stream, mode='r|xz') as archive:
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
        while stream.read(128 * 1024):
            pass
    if not ASSETS.issubset(selected):
        raise ValueError('incomplete Claude desktop payload')
    if not any(n.startswith('app.asar.unpacked/') for n in selected):
        raise ValueError('missing Claude unpacked resources')
    return selected


def read_app_package(archive, version):
    with archive.open('rb') as f:
        marker, offset, _, n = struct.unpack('<4I', f.read(16))
        if marker != 4 or not 0 < n <= min(offset, 16 * 1024 * 1024):
            raise ValueError('invalid Claude ASAR index')
        header = json.loads(f.read(n))
        pkg = header['files']['package.json']
        f.seek(8 + offset + int(pkg['offset']))
        data = json.loads(f.read(int(pkg['size'])))
    if data.get('version') != version or data.get('main') != '.vite/build/launcher.js':
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
        package = read_app_package(selected['app.asar'][0], vendor_pin()[0])
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
