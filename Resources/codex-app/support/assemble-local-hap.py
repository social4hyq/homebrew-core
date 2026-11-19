#!/usr/bin/env python3
"""Assemble a local-only ChatGPT HAP from the pinned official ARM64 Debian package."""
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

VERSION = "26.1111.71704"
BUNDLE_ID = "com.social4hyq.chatgpt"
DEB_SHA256 = "f0550dee1f99127d357ad760aef739c557d49bd67728d2f105d00a7a4780f740"
DEB_ROOT = "usr/lib/chatgpt/resources/"
OWL_RUNTIME = "usr/lib/chatgpt/owl-shell-runtime.json"
HAP_ROOT = "resources/resfile/resources/"
APP_ROOT = HAP_ROOT + "app/"
ICON_SHA256 = "cfe031774dd6aabdceca35338f329bc4844592767d043b7b4a56d8fb097dffd0"
WORK = Path(__file__).resolve().parent


def sha256(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def asar_entry(archive, name):
    with archive.open("rb") as stream:
        marker, offset, _, header_size = struct.unpack("<4I", stream.read(16))
        if marker != 4 or not 0 < header_size <= min(offset, 16 * 1024 * 1024):
            raise ValueError("invalid ChatGPT ASAR header")
        header = json.loads(stream.read(header_size))
        entry = header
        for part in PurePosixPath(name).parts:
            entry = entry["files"][part]
        if "offset" not in entry or "size" not in entry:
            raise ValueError(f"ASAR entry is not a regular file: {name}")
        stream.seek(8 + offset + int(entry["offset"]))
        data = stream.read(int(entry["size"]))
        if len(data) != int(entry["size"]):
            raise ValueError(f"truncated ASAR entry: {name}")
        return data


def selected_payload(deb, scratch):
    if sha256(deb) != DEB_SHA256:
        raise ValueError(f"official ChatGPT {VERSION} package SHA-256 mismatch")
    selected = {}
    ar = subprocess.Popen(["ar", "p", str(deb), "data.tar.xz"], stdout=subprocess.PIPE)
    try:
        with tarfile.open(fileobj=ar.stdout, mode="r|xz") as package:
            for member in package:
                name = member.name.removeprefix("./")
                if name == OWL_RUNTIME:
                    relative = "@root/owl-shell-runtime.json"
                elif name.startswith(DEB_ROOT):
                    relative = name[len(DEB_ROOT):]
                else:
                    continue
                if not relative or relative in selected:
                    raise ValueError(f"duplicate or empty ChatGPT resource path: {relative}")
                path = PurePosixPath(relative)
                if path.is_absolute() or ".." in path.parts:
                    raise ValueError(f"unsafe ChatGPT resource path: {relative}")
                if member.isdir():
                    continue
                if not member.isfile():
                    raise ValueError(f"unsupported Debian resource entry: {relative}")
                target = scratch / str(len(selected))
                source = package.extractfile(member)
                if source is None:
                    raise ValueError(f"cannot read Debian resource: {relative}")
                with source, target.open("wb") as output:
                    shutil.copyfileobj(source, output)
                selected[relative] = (target, member.mode)
        if ar.wait():
            raise RuntimeError("failed to read the official Debian data archive")
    finally:
        if ar.poll() is None:
            ar.kill()
            ar.wait()

    required = {
        "app.asar", "icon-chatgpt.png", "owl-electron-app.json", "owl-app.ini",
        "@root/owl-shell-runtime.json",
    }
    if not required.issubset(selected):
        raise ValueError("official ChatGPT package is missing required app resources")
    if not any(name.startswith("app.asar.unpacked/") for name in selected):
        raise ValueError("official ChatGPT package is missing unpacked native modules")
    if sha256(selected["icon-chatgpt.png"][0]) != ICON_SHA256:
        raise ValueError("official ChatGPT icon hash mismatch")

    package = json.loads(asar_entry(selected["app.asar"][0], "package.json"))
    if (package.get("version") != VERSION or package.get("name") != "openai-codex-electron"
            or package.get("main") != ".vite/build/early-bootstrap.js"):
        raise ValueError("unexpected official ChatGPT ASAR metadata")
    return selected


def assemble(shell, deb, output):
    if output.exists():
        raise FileExistsError(f"refusing to overwrite {output}")
    with tempfile.TemporaryDirectory(prefix="chatgpt-resources-") as temp:
        selected = selected_payload(deb, Path(temp))
        with zipfile.ZipFile(shell) as source:
            names = source.namelist()
            vendor_payload = any(
                name.startswith(APP_ROOT + "vendor.asar") for name in names
            )
            if "module.json" not in names or len(names) != len(set(names)) or vendor_payload:
                raise ValueError("expected a freshly built, shell-only Electron HAP")
            module = json.loads(source.read("module.json"))
            if module.get("app", {}).get("bundleName") != BUNDLE_ID:
                raise ValueError("Electron shell was not built with the ChatGPT bundle ID")
            if module.get("module", {}).get("name") != "electron":
                raise ValueError("unexpected Electron shell module name")

            with output.open("xb") as file, zipfile.ZipFile(file, "w", allowZip64=True) as target:
                for entry in source.infolist():
                    if entry.filename.startswith(APP_ROOT):
                        continue
                    with source.open(entry) as incoming, target.open(entry, "w") as outgoing:
                        shutil.copyfileobj(incoming, outgoing)

                wrapper = {
                    "name": "chatgpt-ohos-shell",
                    "productName": "ChatGPT",
                    "version": VERSION,
                    "main": "chatgpt-bootstrap.cjs",
                }
                target.writestr(APP_ROOT + "package.json", json.dumps(wrapper))
                target.write(WORK / "chatgpt-bootstrap.cjs", APP_ROOT + "chatgpt-bootstrap.cjs")

                for name, (payload, mode) in selected.items():
                    if name == "@root/owl-shell-runtime.json":
                        path = HAP_ROOT + "owl-shell-runtime.json"
                    elif name == "app.asar":
                        path = APP_ROOT + "vendor.asar"
                    elif name.startswith("app.asar.unpacked/"):
                        path = APP_ROOT + "vendor.asar.unpacked/" + name.removeprefix("app.asar.unpacked/")
                    else:
                        path = HAP_ROOT + name
                    info = zipfile.ZipInfo(path)
                    info.create_system = 3
                    info.external_attr = (0o100000 | mode) << 16
                    info.compress_type = zipfile.ZIP_STORED
                    with payload.open("rb") as incoming, target.open(info, "w") as outgoing:
                        shutil.copyfileobj(incoming, outgoing, 1024 * 1024)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("shell", type=Path)
    parser.add_argument("deb", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    assemble(args.shell.resolve(), args.deb.resolve(), args.output.resolve())


if __name__ == "__main__":
    main()
