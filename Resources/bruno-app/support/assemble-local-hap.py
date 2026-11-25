#!/usr/bin/env python3
"""Assemble an unsigned Bruno HAP locally from a verified official arm64 .deb.

The bottle ships only a tap-authored Electron-OHOS shell. At install time we
download Bruno's official arm64 .deb, verify its SHA-256, and inject its
app.asar + app.asar.unpacked into a copy of the shell HAP. Windows-only native
addons are trimmed; the bundled node addons that cannot load on OHOS are
stubbed by the bootstrap instead of being shipped.
"""
import argparse
import hashlib
import io
import json
import os
import shutil
import tarfile
import tempfile
import zipfile
from pathlib import Path

APP_BUNDLE_ID = 'com.social4hyq.bruno'
DEB_ROOT = 'opt/Bruno/resources/'
HAP = 'resources/resfile/resources/'
APP_ROOT = HAP + 'app/'
WORK = Path(__file__).resolve().parent
ASAR = 'app.asar'
UNPACKED = 'app.asar.unpacked/'
# Windows-only native addons that are never loaded on OHOS; trimming them keeps
# the HAP small and avoids shipping unusable binaries.
TRIMMED = {
    'node_modules/native-reg/build/Release/reg.node',
    'node_modules/native-reg/prebuilds/win32-x64/node.napi.node',
    'node_modules/native-reg/prebuilds/win32-ia32/node.napi.node',
    'node_modules/native-reg/prebuilds/win32-arm64/node.napi.node',
    'node_modules/@lydell/node-pty-linux-x64/pty.node',
    'node_modules/@lydell/node-pty-linux-arm64/pty.node',
}


def vendor_pin():
    with open(os.environ['BRUNO_APP_VENDOR_JSON'], encoding='utf-8') as stream:
        pin = json.load(stream)
    return pin['version'], pin['sha256']


def checked_sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


class DebMemberReader(io.RawIOBase):
    def __init__(self, file, start, size):
        super().__init__(); self._file=file; self._start=start; self._size=size; self._pos=0
    def readable(self): return True
    def seekable(self): return True
    def tell(self): return self._pos
    def seek(self, offset, whence=0):
        target = offset if whence==0 else (self._pos+offset if whence==1 else self._size+offset)
        self._pos = max(0, min(target, self._size)); return self._pos
    def readinto(self, b):
        want = min(len(b), self._size-self._pos)
        if want <= 0: return 0
        self._file.seek(self._start+self._pos)
        got = self._file.readinto(memoryview(b)[:want]) or 0
        self._pos += got; return got
    def read(self, size=-1):
        buf = bytearray(self._size-self._pos if size<0 else size)
        return bytes(buf[:self.readinto(buf)])
    def close(self):
        if not self.closed:
            try: self._file.close()
            finally: super().close()


def deb_member(deb, member):
    file = deb.open('rb')
    try:
        if file.read(8) != b'!<arch>\n':
            raise ValueError(f'{deb} is not a Debian package')
        while True:
            header = file.read(60)
            if len(header) < 60: raise ValueError(f'no {member} member in {deb}')
            name = header[:16].decode('ascii','replace').rstrip().rstrip('/')
            size = int(header[48:58].decode('ascii').strip() or '0')
            if name == member: return DebMemberReader(file, file.tell(), size)
            file.seek(size + (size % 2), 1)
    except Exception:
        file.close(); raise


def selected_payload(deb, stage):
    version, sha256 = vendor_pin()
    if checked_sha(deb) != sha256:
        raise ValueError(f'vendor package SHA-256 mismatch for Bruno {version}')
    selected = {}
    with deb_member(deb, 'data.tar.xz') as stream:
        with tarfile.open(fileobj=stream, mode='r|xz') as archive:
            for member in archive:
                name = member.name.removeprefix('./')
                if not name.startswith(DEB_ROOT): continue
                rel = name[len(DEB_ROOT):]
                if rel != ASAR and not rel.startswith(UNPACKED): continue
                if not member.isfile(): continue
                trimmed = rel[len(UNPACKED):] if rel.startswith(UNPACKED) else rel
                if trimmed in TRIMMED: continue
                if '..' in Path(rel).parts or rel.startswith('/') or rel in selected:
                    raise ValueError(f'invalid or duplicate vendor member: {rel}')
                target = stage/str(len(selected))
                with archive.extractfile(member) as inp, target.open('wb') as out:
                    shutil.copyfileobj(inp, out)
                selected[rel] = (target, member.mode)
        while stream.read(128*1024): pass
    if ASAR not in selected:
        raise ValueError('incomplete Bruno payload: missing app.asar')
    if not any(n.startswith(UNPACKED) for n in selected):
        raise ValueError('missing Bruno unpacked resources')
    return selected, version


def assemble(shell, deb, output):
    with tempfile.TemporaryDirectory(prefix='bruno-payload-') as temp:
        stage = Path(temp)
        selected, version = selected_payload(deb, stage)
        with zipfile.ZipFile(shell) as src:
            entries = src.namelist()
            if ('module.json' not in entries or len(set(entries)) != len(entries)
                    or any(n.startswith(APP_ROOT+'vendor.asar') for n in entries)):
                raise ValueError('expected a shell-only HAP with no vendor payload')
            module = json.loads(src.read('module.json'))
            if module['app']['bundleName'] != APP_BUNDLE_ID:
                raise ValueError(f'expected Bruno bundle {APP_BUNDLE_ID}')
            with output.open('xb') as out, zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as dst:
                for entry in src.infolist():
                    if entry.filename.startswith(APP_ROOT): continue
                    with src.open(entry) as inp, dst.open(entry,'w') as target:
                        shutil.copyfileobj(inp, target)
                wrapper = {"name":"bruno-ohos-shell","productName":"Bruno","version":version,"main":"bruno-bootstrap.cjs"}
                dst.writestr(APP_ROOT+'package.json', json.dumps(wrapper))
                dst.write(WORK/'bruno-bootstrap.cjs', APP_ROOT+'bruno-bootstrap.cjs')
                for name, (file, mode) in selected.items():
                    target = APP_ROOT+'vendor.asar' if name == ASAR else APP_ROOT+'vendor.asar.unpacked/'+name[len(UNPACKED):]
                    info = zipfile.ZipInfo(target)
                    info.create_system = 3
                    info.external_attr = (0o100000 | mode) << 16
                    info.compress_type = zipfile.ZIP_STORED
                    with file.open('rb') as inp, dst.open(info,'w') as out:
                        shutil.copyfileobj(inp, out)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    for arg in ('shell','deb','output'):
        parser.add_argument(arg, type=Path)
    a = parser.parse_args()
    if a.output.exists(): parser.error('output already exists')
    assemble(a.shell.resolve(), a.deb.resolve(), a.output.resolve())
