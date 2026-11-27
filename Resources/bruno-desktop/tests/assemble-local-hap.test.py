#!/usr/bin/env python3
"""Tests for the Bruno HAP assembler using a synthetic vendor .deb and shell HAP."""
import importlib.util
import io
import json
import os
import sys
import tarfile
import tempfile
import zipfile
from pathlib import Path

sys.dont_write_bytecode = True
WORK = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("assemble", WORK / "support" / "assemble-local-hap.py")
assemble = importlib.util.module_from_spec(spec)
spec.loader.exec_module(assemble)


def make_deb(path, files):
    """Build a minimal ar with a data.tar.xz containing the given members."""
    data = io.BytesIO()
    with tarfile.open(fileobj=data, mode="w:xz") as tar:
        for name, content in files.items():
            info = tarfile.TarInfo(name)
            info.size = len(content)
            tar.addfile(info, io.BytesIO(content))
    payload = data.getvalue()
    with path.open("wb") as f:
        f.write(b"!<arch>\n")
        # ar header: name(16) mtime(12) uid(6) gid(6) mode(8) size(10) fmag(2)
        header = ("data.tar.xz/".ljust(16) + "0".ljust(12) + "0".ljust(6)
                  + "0".ljust(6) + "100644".ljust(8) + str(len(payload)).ljust(10) + "`\n")
        f.write(header.encode("ascii"))
        f.write(payload)
        if len(payload) % 2:
            f.write(b"\n")


def make_shell(path):
    with zipfile.ZipFile(path, "w") as z:
        module = {"app": {"bundleName": assemble.APP_BUNDLE_ID, "versionName": "4.4.0"},
                  "module": {"name": "electron"}}
        z.writestr("module.json", json.dumps(module))
        z.writestr("resources/resfile/resources/app/package.json", "{}")


def base_files():
    root = assemble.DEB_ROOT
    return {
        root + "app.asar": b"fake asar payload",
        root + assemble.UNPACKED + "node_modules/@lydell/node-pty-linux-arm64/pty.node": b"GLIBC ELF",
        root + assemble.UNPACKED + "node_modules/native-reg/build/Release/reg.node": b"WIN ELF",
        root + assemble.UNPACKED + "node_modules/something/index.js": b"// ok",
    }


def main():
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        for helper in ("bruno-bootstrap.cjs",):
            assemble.WORK = tmp
            (tmp / helper).write_bytes((WORK / "app" / helper).read_bytes())
        deb = tmp / "bruno.deb"
        make_deb(deb, base_files())
        shell = tmp / "shell.hap"
        make_shell(shell)
        out = tmp / "assembled.hap"
        pin = tmp / "vendor.json"
        pin.write_text(json.dumps({"version": "4.4.0", "sha256": assemble.checked_sha(deb)}))
        os.environ["BRUNO_APP_VENDOR_JSON"] = str(pin)

        # selection trims windows-only + glibc pty addons
        stage = tmp / "stage"
        stage.mkdir()
        selected, version = assemble.selected_payload(deb, stage)
        assert version == "4.4.0"
        assert "app.asar" in selected
        assert not any("node-pty-linux-arm64" in n for n in selected)
        assert not any("native-reg" in n for n in selected)

        # wrong sha256 rejected
        pin.write_text(json.dumps({"version": "4.4.0", "sha256": "0" * 64}))
        try:
            assemble.selected_payload(deb, tmp / "stage2")
            raise AssertionError("sha256 mismatch not rejected")
        except ValueError as exc:
            assert "SHA-256" in str(exc)
        pin.write_text(json.dumps({"version": "4.4.0", "sha256": assemble.checked_sha(deb)}))

        # assembly injects bootstrap + asar under vendor.asar
        assemble.assemble(shell, deb, out)
        with zipfile.ZipFile(out) as z:
            names = set(z.namelist())
            assert assemble.APP_ROOT + "bruno-bootstrap.cjs" in names
            assert assemble.APP_ROOT + "vendor.asar" in names
            wrapper = json.loads(z.read(assemble.APP_ROOT + "package.json"))
            assert wrapper["main"] == "bruno-bootstrap.cjs"
            assert not any("reg.node" in n for n in names)
    print("assemble-local-hap tests: OK")


if __name__ == "__main__":
    main()
