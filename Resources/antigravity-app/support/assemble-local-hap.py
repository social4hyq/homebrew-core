#!/usr/bin/env python3
"""Inject the prepared official language server into a shell-only Antigravity HAP."""
import argparse
import hashlib
import json
import os
import stat
import tempfile
import zipfile
from pathlib import Path

BUNDLE_ID = "com.social4hyq.antigravity"
RUNTIME = "libs/arm64-v8a/"
LS_NAME = "antigravity-language-server.bin"
LS_PATH = RUNTIME + LS_NAME
APP_ROOT = "resources/resfile/resources/app/"
ACL_PERMISSIONS = [
    "ohos.permission.CUSTOM_SANDBOX",
    "ohos.permission.READ_WRITE_USER_FILE",
    "ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY",
    "ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION",
]


def sha256(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def check_vendor(ls, pin_path):
    with open(pin_path, encoding="utf-8") as stream:
        pin = json.load(stream)
    want = pin.get("languageServerSha256")
    if not want:
        raise ValueError("vendor.json is missing languageServerSha256")
    if sha256(ls) != want:
        raise ValueError("prepared language server SHA-256 mismatch")


def verify_tarball(tarball, pin_path):
    """Build-time check: pinned official tarball has the expected engine member."""
    with open(pin_path, encoding="utf-8") as stream:
        pin = json.load(stream)
    if sha256(tarball) != pin["sha256"]:
        raise ValueError("official Antigravity tarball SHA-256 mismatch")
    wanted = "Antigravity-arm64/resources/bin/language_server"
    import tarfile
    with tarfile.open(tarball, "r:gz") as archive:
        if not any(name.endswith("/resources/bin/language_server") for name in archive.getnames()):
            raise ValueError("official tarball is missing resources/bin/language_server")


def assemble(shell, ls, output, pin_path):
    if output.exists():
        raise FileExistsError(f"refusing to overwrite {output}")
    check_vendor(ls, pin_path)
    mode = ls.stat().st_mode & 0o777
    if not mode & stat.S_IXUSR:
        raise ValueError("prepared language server is not executable")

    with zipfile.ZipFile(shell) as source:
        names = source.namelist()
        if len(names) != len(set(names)) or "module.json" not in names:
            raise ValueError("expected a shell-only Electron HAP")
        if APP_ROOT + "antigravity-bootstrap.cjs" not in names:
            raise ValueError("shell HAP is missing the Antigravity bootstrap")
        if LS_PATH in names:
            raise ValueError("shell HAP already contains a language server")
        module = json.loads(source.read("module.json"))
        if module.get("app", {}).get("bundleName") != BUNDLE_ID:
            raise ValueError("Electron shell was not built with the Antigravity bundle ID")

        module_info = module.setdefault("module", {})
        requests = module_info.setdefault("requestPermissions", [])
        known = {item.get("name") for item in requests if isinstance(item, dict)}
        for permission in ACL_PERMISSIONS:
            if permission not in known:
                requests.append({"name": permission})
        binaries = module_info.setdefault("executableBinaryPaths", [])
        paths = {item.get("path") if isinstance(item, dict) else item for item in binaries}
        if LS_PATH not in paths:
            binaries.append({"path": LS_PATH})
        module_bytes = json.dumps(module, separators=(",", ":"), ensure_ascii=False).encode()

        output.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(prefix=output.name + ".", dir=output.parent, delete=False) as tmp:
            tmp_path = Path(tmp.name)
        try:
            with zipfile.ZipFile(tmp_path, "w", allowZip64=True) as target:
                for entry in source.infolist():
                    payload = module_bytes if entry.filename == "module.json" else source.read(entry)
                    if entry.filename == "module.json":
                        target.writestr(entry, payload)
                    else:
                        target.writestr(entry, payload)
                info = zipfile.ZipInfo(LS_PATH)
                info.create_system = 3
                info.external_attr = (0o100000 | mode) << 16
                info.compress_type = zipfile.ZIP_STORED
                with ls.open("rb") as incoming, target.open(info, "w") as outgoing:
                    while True:
                        chunk = incoming.read(1024 * 1024)
                        if not chunk:
                            break
                        outgoing.write(chunk)
            os.replace(tmp_path, output)
        except Exception:
            tmp_path.unlink(missing_ok=True)
            raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("shell", type=Path)
    parser.add_argument("language_server", type=Path)
    parser.add_argument("vendor_json", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    assemble(args.shell.resolve(), args.language_server.resolve(),
             args.output.resolve(), args.vendor_json.resolve())


if __name__ == "__main__":
    main()
