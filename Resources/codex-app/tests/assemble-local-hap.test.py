#!/usr/bin/env python3
"""Exercise the HAP assembler with a tiny shell and controlled vendor payload."""
import importlib.util
import json
import shutil
import struct
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


if __name__ == "__main__":
    main()
