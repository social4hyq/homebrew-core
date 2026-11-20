#!/usr/bin/env python3
"""Exercise the HAP assembler with a tiny shell and controlled vendor payload."""
import importlib.util
import io
import json
import lzma
import shutil
import struct
import tarfile
import tempfile
import zipfile
from pathlib import Path

RESOURCE = Path(__file__).resolve().parent.parent
ASSEMBLER = RESOURCE / "support/assemble-local-hap.py"
BOOTSTRAP = RESOURCE / "app/chatgpt-bootstrap.cjs"


def load_module(script):
    spec = importlib.util.spec_from_file_location("chatgpt_assembler", script)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main():
    with tempfile.TemporaryDirectory(prefix="chatgpt-assembler-test-") as temp:
        root = Path(temp)
        support = root / "support"
        support.mkdir()
        script = support / ASSEMBLER.name
        shutil.copy2(ASSEMBLER, script)
        shutil.copy2(BOOTSTRAP, support / BOOTSTRAP.name)
        shims = sorted(BOOTSTRAP.parent.glob("owl-*.cjs"))
        assert shims, "missing Owl compatibility shims"
        for shim in shims:
            shutil.copy2(shim, support / shim.name)
        assembler = load_module(script)

        payload_root = root / "payload"
        payload_root.mkdir()
        names = [
            "app.asar", "icon-chatgpt.png", "owl-electron-app.json", "owl-app.ini",
            "@root/owl-shell-runtime.json", "app.asar.unpacked/native.node",
            "codex", "codex-code-mode-host",
        ]
        selected = {}
        for name in names:
            file = payload_root / str(len(selected))
            file.write_bytes(name.encode())
            selected[name] = (file, 0o644)
        assembler.selected_payload = lambda _deb, _scratch: selected

        shell = root / "shell.hap"
        module_json = {
            "app": {"bundleName": assembler.BUNDLE_ID},
            "module": {"name": "electron"},
        }
        with zipfile.ZipFile(shell, "w") as archive:
            archive.writestr("module.json", json.dumps(module_json))
            archive.writestr(assembler.APP_ROOT + "template-placeholder", b"remove me")
            archive.writestr("resources.index", b"shell resources")

        output = root / "assembled.hap"
        assembler.assemble(shell, root / "unused.deb", output)
        with zipfile.ZipFile(output) as archive:
            assert archive.testzip() is None
            assert assembler.APP_ROOT + "template-placeholder" not in archive.namelist()
            assert archive.read(assembler.APP_ROOT + "chatgpt-bootstrap.cjs") == BOOTSTRAP.read_bytes()
            for shim in shims:
                assert archive.read(assembler.APP_ROOT + shim.name) == shim.read_bytes()
            assert archive.read(assembler.APP_ROOT + "vendor.asar") == b"app.asar"
            assert archive.read(assembler.APP_ROOT + "package.json") == json.dumps({
                "name": "chatgpt-ohos-shell",
                "productName": "ChatGPT",
                "version": assembler.VERSION,
                "main": "chatgpt-bootstrap.cjs",
            }).encode()
            assert archive.read(assembler.HAP_ROOT + "owl-shell-runtime.json") == b"@root/owl-shell-runtime.json"
            unpacked = archive.read(assembler.APP_ROOT + "vendor.asar.unpacked/native.node")
            assert unpacked == b"app.asar.unpacked/native.node"

        package = json.dumps({"files": {"package.json": {"size": 2, "offset": "0"}}},
                             separators=(",", ":")).encode()
        package_bytes = b"{}"
        asar = root / "test.asar"
        asar.write_bytes(struct.pack("<4I", 4, len(package) + 8, 0, len(package)) + package + package_bytes)
        assert assembler.asar_entry(asar, "package.json") == package_bytes

        # Real selected_payload path: stream data.tar.xz from a synthetic .deb
        # (an ar archive) without binutils.
        def write_ar(path, members):
            blob = io.BytesIO()
            blob.write(b"!<arch>\n")
            for name, data in members.items():
                assert len(name) <= 16
                blob.write(name.ljust(16).encode() + b"0".ljust(12) + b"0".ljust(6)
                           + b"0".ljust(6) + b"100644".ljust(8)
                           + str(len(data)).ljust(10).encode() + b"`\n")
                blob.write(data)
                if len(data) % 2:
                    blob.write(b"\n")
            path.write_bytes(blob.getvalue())

        inner = io.BytesIO()
        with tarfile.open(fileobj=inner, mode="w") as tar:
            payload = b"tar-payload"
            info = tarfile.TarInfo("./usr/lib/chatgpt/resources/icon-chatgpt.png")
            info.size = len(payload)
            tar.addfile(info, io.BytesIO(payload))
        fake_deb = root / "fixture.deb"
        data_member = lzma.compress(inner.getvalue())
        write_ar(fake_deb, {
            "debian-binary": b"2.0\n",
            "control.tar.gz": b"control",
            "data.tar.xz": data_member,
        })
        with assembler.deb_member(fake_deb, "data.tar.xz") as stream:
            assert stream.read() == data_member


if __name__ == "__main__":
    main()
