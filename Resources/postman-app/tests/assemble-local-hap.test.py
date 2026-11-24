#!/usr/bin/env python3
"""Tests for the Postman HAP assembler. Uses a synthetic vendor tarball and shell HAP."""
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


def make_tarball(path, members):
    with tarfile.open(path, "w:gz") as tar:
        for name, data in members.items():
            info = tarfile.TarInfo(name)
            info.size = len(data)
            tar.addfile(info, io.BytesIO(data))


def make_shell(path, version="12.38.0"):
    with zipfile.ZipFile(path, "w") as z:
        module = {"app": {"bundleName": assemble.APP_BUNDLE_ID, "versionName": version},
                  "module": {"name": "electron"}}
        z.writestr("module.json", json.dumps(module))
        # A real libelectron.so carries the fuse wire; fake a minimal marker blob.
        z.writestr(assemble.ELECTRON_LIB, b"x" * 64 + assemble.FUSE_SENTINEL +
                   bytes([1, 2, 0, ord("1")]))


def base_members(version="12.38.0"):
    root = assemble.VENDOR_ROOT
    return {
        root + "main.js": b"console.log('postman');\n",
        root + "package.json": json.dumps({"name": "Postman", "version": version, "main": "main.js"}).encode(),
        root + "assets/icon.png": b"\x89PNG\r\n\x1a\n" + b"0" * 64,
        root + "node_modules/native_modules/build/Release/keytar.node": b"GLIBC ELF",
        root + "node_modules/native_modules/prebuilds/linux-arm64/node.napi.glibc.node": b"GLIBC ELF",
        root + "js/runtime.js": b"// ok\n",
    }


def main():
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        # The formula copies the bootstrap beside the assembler into assemble/;
        # mirror that layout in a temp dir for the test.
        assemble_dir = tmp / "assemble"
        assemble_dir.mkdir()
        (assemble_dir / "postman-bootstrap.cjs").write_bytes(
            (WORK / "app" / "postman-bootstrap.cjs").read_bytes())
        assemble.WORK = assemble_dir
        tarball = tmp / "postman.tar.gz"
        make_tarball(tarball, base_members())
        shell = tmp / "shell.hap"
        make_shell(shell)
        out = tmp / "assembled.hap"
        pin = tmp / "vendor.json"
        pin.write_text(json.dumps({"version": "12.38.0", "sha256": assemble.checked_sha(tarball)}))
        os.environ["POSTMAN_APP_VENDOR_JSON"] = str(pin)

        # Selection trims native addons and keeps JS.
        stage = tmp / "stage"
        stage.mkdir()
        count = assemble.selected_payload(tarball, stage)
        assert (stage / "main.js").is_file()
        assert (stage / "js/runtime.js").is_file()
        assert not (stage / "node_modules/native_modules/build/Release/keytar.node").exists()
        assert not (stage / "node_modules/native_modules/prebuilds/linux-arm64/node.napi.glibc.node").exists()
        assert count >= 4

        # Wrong sha256 is rejected.
        pin.write_text(json.dumps({"version": "12.38.0", "sha256": "0" * 64}))
        try:
            assemble.selected_payload(tarball, tmp / "stage2")
            raise AssertionError("sha256 mismatch was not rejected")
        except ValueError as exc:
            assert "SHA-256" in str(exc)
        pin.write_text(json.dumps({"version": "12.38.0", "sha256": assemble.checked_sha(tarball)}))

        # Assembly injects bootstrap + app tree under vendor/ and drops shell app.
        assemble.assemble(shell, tarball, out)
        with zipfile.ZipFile(out) as z:
            names = set(z.namelist())
            assert assemble.APP_ROOT + "postman-bootstrap.cjs" in names
            assert assemble.APP_ROOT + "vendor/main.js" in names
            assert assemble.APP_ROOT + "vendor/js/runtime.js" in names
            wrapper = json.loads(z.read(assemble.APP_ROOT + "package.json"))
            assert wrapper["main"] == "postman-bootstrap.cjs"
            assert not any("keytar.node" in n for n in names)
    print("assemble-local-hap tests: OK")


if __name__ == "__main__":
    main()
