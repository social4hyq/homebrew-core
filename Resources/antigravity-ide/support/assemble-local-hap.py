#!/usr/bin/env python3
"""Inject the official Antigravity IDE app tree into a shell-only HAP."""
import argparse
import hashlib
import json
import os
import shutil
import tempfile
import zipfile
from pathlib import Path

BUNDLE_ID = "com.social4hyq.antigravityide"
APP_ROOT = "resources/resfile/resources/app/"
VENDOR_PARENT = APP_ROOT + "vendor/"
ACL_PERMISSIONS = [
    "ohos.permission.CUSTOM_SANDBOX",
    "ohos.permission.READ_WRITE_USER_FILE",
    "ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY",
    "ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION",
]


def sha256(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def verify_tarball(tarball, pin_path):
    with open(pin_path, encoding="utf-8") as stream:
        pin = json.load(stream)
    if sha256(tarball) != pin["sha256"]:
        raise ValueError("official Antigravity IDE tarball SHA-256 mismatch")
    import tarfile
    with tarfile.open(tarball, "r:gz") as archive:
        if not any(name.endswith("/resources/app/out/main.js") for name in archive.getnames()):
            raise ValueError("official tarball is missing resources/app/out/main.js")


def selected_app(tarball, scratch):
    import tarfile
    prefix = "Antigravity IDE/resources/app/"
    with tarfile.open(tarball, "r:gz") as archive:
        for member in archive:
            if not member.name.startswith(prefix):
                continue
            relative = member.name[len(prefix):]
            if not relative or relative.startswith("/") or ".." in Path(relative).parts:
                raise ValueError(f"unsafe vendor path: {relative}")
            target = scratch / relative
            if member.isdir():
                target.mkdir(parents=True, exist_ok=True)
                continue
            if not member.isfile():
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            source = archive.extractfile(member)
            if source is None:
                raise ValueError(f"cannot read vendor file: {relative}")
            with source, target.open("wb") as output:
                shutil.copyfileobj(source, output)
    if not (scratch / "out/main.js").is_file():
        raise ValueError("vendor app is missing out/main.js")


def assemble(shell, tarball, output, pin_path):
    if output.exists():
        raise FileExistsError(f"refusing to overwrite {output}")
    verify_tarball(tarball, pin_path)
    with tempfile.TemporaryDirectory(prefix="antigravity-ide-vendor-") as temp:
        vendor = Path(temp) / "app"
        vendor.mkdir()
        selected_app(tarball, vendor)
        with zipfile.ZipFile(shell) as source:
            names = source.namelist()
            if len(names) != len(set(names)) or "module.json" not in names:
                raise ValueError("expected a shell-only Electron HAP")
            if APP_ROOT + "antigravity-ide-bootstrap.cjs" not in names:
                raise ValueError("shell HAP is missing the IDE bootstrap")
            module = json.loads(source.read("module.json"))
            if module.get("app", {}).get("bundleName") != BUNDLE_ID:
                raise ValueError("Electron shell was not built with the Antigravity IDE bundle ID")
            module_info = module.setdefault("module", {})
            requests = module_info.setdefault("requestPermissions", [])
            known = {item.get("name") for item in requests if isinstance(item, dict)}
            for permission in ACL_PERMISSIONS:
                if permission not in known:
                    requests.append({"name": permission})
            module_bytes = json.dumps(module, separators=(",", ":"), ensure_ascii=False).encode()

            output.parent.mkdir(parents=True, exist_ok=True)
            with tempfile.NamedTemporaryFile(prefix=output.name + ".", dir=output.parent, delete=False) as tmp:
                tmp_path = Path(tmp.name)
            try:
                with zipfile.ZipFile(tmp_path, "w", allowZip64=True) as target:
                    for entry in source.infolist():
                        payload = module_bytes if entry.filename == "module.json" else source.read(entry)
                        target.writestr(entry, payload)
                    for path in sorted(vendor.rglob("*")):
                        relative = path.relative_to(vendor).as_posix()
                        zip_path = VENDOR_PARENT + relative
                        if path.is_dir():
                            continue
                        info = zipfile.ZipInfo(zip_path)
                        info.create_system = 3
                        info.external_attr = (0o100000 | (path.stat().st_mode & 0o777)) << 16
                        info.compress_type = zipfile.ZIP_STORED
                        with path.open("rb") as incoming, target.open(info, "w") as outgoing:
                            shutil.copyfileobj(incoming, outgoing, 1024 * 1024)
                os.replace(tmp_path, output)
            except Exception:
                tmp_path.unlink(missing_ok=True)
                raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("shell", type=Path)
    parser.add_argument("tarball", type=Path)
    parser.add_argument("vendor_json", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    assemble(args.shell.resolve(), args.tarball.resolve(),
             args.output.resolve(), args.vendor_json.resolve())


if __name__ == "__main__":
    main()
