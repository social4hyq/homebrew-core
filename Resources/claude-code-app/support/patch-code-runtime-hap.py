#!/usr/bin/env python3
"""Patch the Claude Code runtime and desktop window options into a built HAP.

This post-packaging step is used when the local DevEco environment lacks the
Hvigor build frontend. It updates the signed vendor source's ASAR integrity
metadata, the HAP module manifest, bootstrap, and app-local runtime. Sign only
after patching.
"""
import argparse
import hashlib
import json
import os
import shutil
import stat
import struct
import subprocess
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
APP_BUNDLE_ID = "com.social4hyq.claudecode"
CLI_SHA256 = "7b6e484b1989a5a14a4b354709ccc8672518a3ec5b9ccd7981fc6254327fde67"
APP = "resources/resfile/resources/app/"
RUNTIME = "libs/arm64-v8a/"
BINARIES = {
    "claude-app-local-launcher.bin": ("claude-app-local-launcher.bin", 0o755),
    "claude-code-probe.bin": ("claude-code-probe.bin", 0o755),
    "claude-glibc-probe.bin": ("claude-glibc-probe.bin", 0o755),
    "libc.so.6": ("libc.so.6", 0o644),
    "libm.so.6": ("libm.so.6", 0o644),
    "libpthread.so.0": ("libpthread.so.0", 0o644),
    "libdl.so.2": ("libdl.so.2", 0o644),
    "librt.so.1": ("librt.so.1", 0o644),
}
EXECUTABLES = [
    RUNTIME + "claude-app-local-launcher.bin",
    RUNTIME + "claude-code-probe.bin",
    RUNTIME + "claude-glibc-probe.bin",
]
REPLACED_HELPERS = {
    APP + "bootstrap.cjs": ROOT / "claude-bootstrap.cjs",
    APP + "claude-ohos-config.cjs": ROOT / "claude-ohos-config.cjs",
}
HOST_CONFIG_PATH = APP + "claude-host-config.json"
ASAR_PATH = APP + "vendor.asar"
BUILD_DIR = ".vite/build/"
# Chunk file names are build hashes, so the Code manager is found by content.
CHUNK_MARKER = b"getHostPlatform(){"
ACL_PERMISSIONS = [
    "ohos.permission.CUSTOM_SANDBOX",
    "ohos.permission.READ_WRITE_USER_FILE",
    "ohos.permission.READ_PASTEBOARD",
    "ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY",
    "ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION",
]


def find_target_chunk(archive: bytes, root: dict, header_size: int) -> str:
    build = root["files"][".vite"]["files"]["build"]["files"]
    found = []
    for name, node in build.items():
        if not (name.startswith("index.chunk-") and name.endswith(".js")) or "offset" not in node:
            continue
        start = 8 + header_size + int(node["offset"])
        if archive.find(CHUNK_MARKER, start, start + int(node["size"])) != -1:
            found.append(BUILD_DIR + name)
    if len(found) != 1:
        raise ValueError(f"expected one Code manager chunk, found {len(found)}")
    return found[0]


def patch_asar(archive: bytes) -> bytes:
    if len(archive) < 16:
        raise ValueError("truncated vendor ASAR")
    marker, header_size, pickle_size, json_size = struct.unpack("<4I", archive[:16])
    if marker != 4 or header_size != pickle_size + 4 or pickle_size < json_size + 4:
        raise ValueError("unexpected vendor ASAR header")
    padding = pickle_size - json_size - 4
    if padding:
        # Newer @electron/asar writes the header through Pickle.writeString,
        # which appends a NUL terminator and zero-pads the pickle to 4 bytes.
        expected = (4 - (json_size + 5) % 4) % 4 + 1
        if padding != expected or archive[16 + json_size:16 + json_size + padding] != b"\0" * padding:
            raise ValueError("unexpected vendor ASAR header padding")
    header_bytes = archive[16:16 + json_size]
    root = json.loads(header_bytes)
    target_chunk = find_target_chunk(archive, root, header_size)
    target = root
    for part in target_chunk.split("/"):
        target = target["files"][part]
    size = int(target["size"])
    start = 8 + header_size + int(target["offset"])
    original = archive[start:start + size]
    if len(original) != size:
        raise ValueError("truncated Code manager chunk")
    # The chunk is megabytes: feeding it through pipes stalls on OHOS, so use files.
    with tempfile.TemporaryFile() as source, tempfile.TemporaryFile() as output:
        source.write(original)
        source.seek(0)
        result = subprocess.run(
            ["node", str(ROOT / "claude-code-platform-patch.cjs")],
            stdin=source,
            stdout=output,
            stderr=subprocess.PIPE,
            check=False,
        )
        if result.returncode:
            raise ValueError("Code manager patch failed: " + result.stderr.decode(errors="replace").strip())
        output.seek(0)
        patched = output.read()
    old_integrity = target.get("integrity")
    if not old_integrity or old_integrity.get("algorithm") != "SHA256":
        raise ValueError("Code manager chunk has no supported ASAR integrity metadata")
    new_integrity = dict(old_integrity)
    block_size = int(new_integrity["blockSize"])
    new_integrity["hash"] = hashlib.sha256(patched).hexdigest()
    new_integrity["blocks"] = [
        hashlib.sha256(patched[i:i + block_size]).hexdigest()
        for i in range(0, len(patched), block_size)
    ]
    target["integrity"] = new_integrity
    payload = []
    next_offset = 0
    target_seen = False

    def pack(node, path):
        nonlocal next_offset, target_seen
        if "files" in node:
            for name, child in node["files"].items():
                pack(child, f"{path}/{name}" if path else name)
            return
        if "link" in node or node.get("unpacked") or "offset" not in node:
            return
        data_size = int(node["size"])
        old_start = 8 + header_size + int(node["offset"])
        data = archive[old_start:old_start + data_size]
        if len(data) != data_size:
            raise ValueError(f"truncated ASAR member: {path}")
        if path == target_chunk:
            data = patched
            target_seen = True
        node["offset"] = str(next_offset)
        node["size"] = len(data)
        next_offset += len(data)
        payload.append(data)

    pack(root, "")
    if not target_seen:
        raise ValueError("target Code manager chunk was not packed")
    new_header = json.dumps(root, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    # Newer @electron/asar Pickle.writeString layout: the 16-byte prefix holds
    # the pickle sizes, the JSON starts at offset 16, then a NUL plus zero
    # padding aligns the pickle payload to 4 bytes.
    tail = new_header + b"\0"
    tail += b"\0" * (-(len(new_header) + 5) % 4)
    header_pickle_size = 4 + len(tail)
    prefix = struct.pack("<4I", 4, header_pickle_size + 4, header_pickle_size,
                         len(new_header))
    return prefix + tail + b"".join(payload)


def copy_entry(src, dst, info, *, data=None):
    if data is not None:
        dst.writestr(info, data)
        return
    with src.open(info, "r") as inp, dst.open(info, "w") as out:
        shutil.copyfileobj(inp, out, 1024 * 1024)


def executable_info(name, mode):
    info = zipfile.ZipInfo(name)
    info.create_system = 3
    info.external_attr = (stat.S_IFREG | mode) << 16
    info.compress_type = zipfile.ZIP_STORED
    return info


def make_host_config(home: str, brew_prefix: str, host_path: str, xdg_config: str = "",
                    xdg_data: str = "", xdg_state: str = "") -> dict:
    if not Path(home).is_absolute() or not Path(brew_prefix).is_absolute():
        raise ValueError("host HOME and Homebrew prefix must be absolute paths")
    home_path = Path(home).resolve()
    prefix_path = Path(brew_prefix).resolve()
    launcher = prefix_path / "opt/claude-code.latest/bin/claude"
    if not launcher.is_file() or not os.access(launcher, os.X_OK):
        raise ValueError(f"Homebrew Claude launcher is missing or not executable: {launcher}")
    if not host_path:
        host_path = f"{prefix_path}/bin:{prefix_path}/sbin:/system/bin:/system/xbin:/usr/bin:/bin:/vendor/bin"
    xdg = {}
    for key, value in (("config", xdg_config), ("data", xdg_data), ("state", xdg_state)):
        if not value:
            continue
        candidate = Path(value)
        if not candidate.is_absolute():
            raise ValueError(f"XDG_{key.upper()}_HOME must be absolute when set")
        # Never bake another HAP's private /data path into this installation.
        if str(candidate).startswith("/storage/") or candidate == home_path or home_path in candidate.parents:
            xdg[key] = str(candidate)
    return {
        "home": str(home_path),
        "brewPrefix": str(prefix_path),
        "claude": str(launcher),
        "claudeConfigDir": str(home_path / ".claude"),
        "path": host_path,
        "xdg": xdg,
        "preflightCli": True,
    }


def patch(input_hap: Path, output_hap: Path, host_config: dict | None,
          runtime_dir: Path | None = None, acl: bool = True):
    if input_hap.resolve() == output_hap.resolve() or output_hap.exists():
        raise ValueError("output must be a new file different from input")
    if not input_hap.is_file():
        raise ValueError("input HAP does not exist")
    if runtime_dir is not None:
        runtime_dir = runtime_dir.resolve()
        for filename, _ in BINARIES.values():
            if not (runtime_dir / filename).is_file():
                raise ValueError(f"missing staged runtime file: {filename}")
        digest = hashlib.file_digest((runtime_dir / "claude-code-probe.bin").open("rb"), "sha256").hexdigest()
        if digest != CLI_SHA256:
            raise ValueError("refusing to package an unverified Claude Code CLI")
    for helper in REPLACED_HELPERS.values():
        if not helper.is_file():
            raise ValueError(f"missing local helper: {helper.name}")

    with zipfile.ZipFile(input_hap) as src:
        names = src.namelist()
        if len(names) != len(set(names)):
            raise ValueError("input HAP has duplicate entries")
        if "module.json" not in names:
            raise ValueError("input is not an OHOS HAP (module.json missing)")
        module = json.loads(src.read("module.json"))
        if module.get("app", {}).get("bundleName") != APP_BUNDLE_ID:
            raise ValueError(f"expected Claude Code bundle {APP_BUNDLE_ID}")
        if APP + "bootstrap.cjs" not in names or APP + "vendor.asar" not in names:
            raise ValueError("input HAP is missing the Claude Desktop payload")
        if not any(name.startswith("libs/arm64-v8a/") for name in names):
            raise ValueError("input HAP has no ARM64 Electron shell libraries")

        module_info = module.setdefault("module", {})
        requests = module_info.setdefault("requestPermissions", [])
        if not isinstance(requests, list):
            raise ValueError("HAP requestPermissions must be a list")
        existing_permissions = {item.get("name") for item in requests if isinstance(item, dict)}
        if acl:
            for permission in ACL_PERMISSIONS:
                if permission not in existing_permissions:
                    requests.append({"name": permission})
        else:
            requests[:] = [item for item in requests
                            if not isinstance(item, dict) or item.get("name") not in ACL_PERMISSIONS]
        old = module_info.get("executableBinaryPaths", []) if runtime_dir is not None else []
        existing = {
            item.get("path") if isinstance(item, dict) else item
            for item in old
        }
        if runtime_dir is not None:
            for path in EXECUTABLES:
                if path not in existing:
                    old.append({"path": path})
        module_info["executableBinaryPaths"] = old
        module_bytes = json.dumps(module, separators=(",", ":"), ensure_ascii=False).encode()

        host_config_bytes = None if host_config is None else (
            json.dumps(host_config, separators=(",", ":"), ensure_ascii=False) + "\n"
        ).encode()
        replacements = {"module.json": module_bytes}
        if host_config_bytes is not None and HOST_CONFIG_PATH in names:
            replacements[HOST_CONFIG_PATH] = host_config_bytes
        for name, path in REPLACED_HELPERS.items():
            replacements[name] = path.read_bytes()
        replacements[ASAR_PATH] = patch_asar(src.read(ASAR_PATH))
        # Rebuilding from an earlier candidate is intentionally idempotent:
        # refresh only these fixed runtime members, preserving all other HAP
        # entries and never introducing duplicate ZIP paths.
        binary_entries = {RUNTIME + name for name in BINARIES} if runtime_dir is not None else set()

        output_hap.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(prefix=output_hap.name + ".", dir=output_hap.parent, delete=False) as tmp:
            tmp_path = Path(tmp.name)
        try:
            with zipfile.ZipFile(tmp_path, "w", allowZip64=True) as dst:
                for info in src.infolist():
                    if info.filename in replacements:
                        dst.writestr(info, replacements.pop(info.filename))
                    elif info.filename == HOST_CONFIG_PATH and host_config is None:
                        continue
                    elif info.filename in binary_entries:
                        continue
                    else:
                        copy_entry(src, dst, info)
                if replacements:
                    raise ValueError(f"missing replaceable HAP entries: {sorted(replacements)}")
                if host_config_bytes is not None and HOST_CONFIG_PATH not in names:
                    info = zipfile.ZipInfo(HOST_CONFIG_PATH)
                    info.create_system = 3
                    info.external_attr = (stat.S_IFREG | 0o644) << 16
                    dst.writestr(info, host_config_bytes)
                if runtime_dir is not None:
                    for name, (_, mode) in BINARIES.items():
                        path = runtime_dir / name
                        info = executable_info(RUNTIME + name, mode)
                        with path.open("rb") as inp, dst.open(info, "w") as out:
                            shutil.copyfileobj(inp, out, 1024 * 1024)
            tmp_path.replace(output_hap)
        except BaseException:
            tmp_path.unlink(missing_ok=True)
            raise


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input_hap", type=Path)
    parser.add_argument("output_hap", type=Path)
    parser.add_argument("--runtime-dir", type=Path,
                        help="optional bundled Claude Code runtime; by default use the host Homebrew CLI")
    parser.add_argument("--no-host-config", action="store_true",
                        help="leave the install-time host configuration out of the HAP")
    parser.add_argument("--host-home", default=os.environ.get("HOME", ""))
    parser.add_argument("--brew-prefix", default=os.environ.get("HOMEBREW_PREFIX", ""))
    parser.add_argument("--host-path", default=os.environ.get("PATH", ""))
    parser.add_argument("--no-acl", action="store_true", help="do not request local developer ACL permissions")
    args = parser.parse_args()
    try:
        home = args.host_home or str(Path.home())
        prefix = args.brew_prefix or str(Path(home) / ".harmonybrew")
        config = None if args.no_host_config else make_host_config(
            home, prefix, args.host_path,
            xdg_config=os.environ.get("XDG_CONFIG_HOME", ""),
            xdg_data=os.environ.get("XDG_DATA_HOME", ""),
            xdg_state=os.environ.get("XDG_STATE_HOME", ""),
        )
        patch(args.input_hap.resolve(), args.output_hap.resolve(), config,
              runtime_dir=args.runtime_dir, acl=not args.no_acl)
    except (OSError, ValueError, zipfile.BadZipFile, json.JSONDecodeError) as error:
        parser.error(str(error))
