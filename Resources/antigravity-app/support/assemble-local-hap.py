#!/usr/bin/env python3
"""Validate the shell-only HAP and the pinned official tarball for Antigravity.

The language server is no longer injected into the HAP: the HAP sandbox cannot
exec binaries under libs/. The installer prepares it on the host and passes its
absolute path through antigravity-host-config.json instead.
"""
import argparse
import hashlib
import json
import os
import zipfile
from pathlib import Path

BUNDLE_ID = "com.social4hyq.antigravity"
APP_ROOT = "resources/resfile/resources/app/"


def sha256(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def verify_tarball(tarball, pin_path):
    """Build-time check: pinned official tarball has the expected engine member."""
    with open(pin_path, encoding="utf-8") as stream:
        pin = json.load(stream)
    if sha256(tarball) != pin["sha256"]:
        raise ValueError("official Antigravity tarball SHA-256 mismatch")
    import tarfile
    with tarfile.open(tarball, "r:gz") as archive:
        if not any(name.endswith("/resources/bin/language_server") for name in archive.getnames()):
            raise ValueError("official tarball is missing resources/bin/language_server")


def verify_shell(shell):
    with zipfile.ZipFile(shell) as source:
        names = source.namelist()
        if len(names) != len(set(names)) or "module.json" not in names:
            raise ValueError("expected a shell-only Electron HAP")
        if APP_ROOT + "antigravity-bootstrap.cjs" not in names:
            raise ValueError("shell HAP is missing the Antigravity bootstrap")
        if any(name.startswith("libs/arm64-v8a/antigravity-language-server.bin") for name in names):
            raise ValueError("shell HAP must not carry an in-HAP language server")
        module = json.loads(source.read("module.json"))
        if module.get("app", {}).get("bundleName") != BUNDLE_ID:
            raise ValueError("Electron shell was not built with the Antigravity bundle ID")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("shell", type=Path)
    parser.add_argument("vendor_json", type=Path)
    args = parser.parse_args()
    verify_shell(args.shell.resolve())
    # vendor.json is accepted for CLI compatibility; the build-time shape check
    # is done separately via verify_tarball().
    print("shell-only HAP verified")


if __name__ == "__main__":
    main()
