#!/usr/bin/env python3
"""Verify that a Snow Shot HAP carries the non-platform ELF runtime closure."""

from __future__ import annotations

import argparse
import re
import stat
import subprocess
import tempfile
import zipfile
from pathlib import Path


NEEDED_PATTERN = re.compile(r"\(NEEDED\).*?\[(.*?)\]")
APP_ELF = "libs/arm64-v8a/libsnow_shot.so"
QPA_ELF = "libs/arm64-v8a/libqohos.so"


def dynamic_needed(readelf: Path, elf: Path) -> list[str]:
    result = subprocess.run(
        [str(readelf), "-d", str(elf)], check=True, capture_output=True, text=True
    )
    return NEEDED_PATTERN.findall(result.stdout)


def reject_compatibility_libraries(names: list[str]) -> None:
    forbidden = sorted(
        name for name in names
        if name.startswith(("libmusl_compat.", "libmusl-compat.", "libmuslext."))
    )
    if forbidden:
        raise SystemExit("Forbidden compatibility libraries:\n" + "\n".join(forbidden))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("hap", type=Path)
    parser.add_argument("--readelf", type=Path, required=True)
    parser.add_argument("--system-lib-dir", type=Path, action="append", default=[])
    args = parser.parse_args()

    with zipfile.ZipFile(args.hap) as archive:
        archive_names = set(archive.namelist())
        if APP_ELF not in archive_names or QPA_ELF not in archive_names:
            raise SystemExit("HAP is missing the app ELF or Qt OHOS platform plugin")

        libs: dict[str, bytes] = {}
        aliases: dict[str, str] = {}
        for info in archive.infolist():
            if not info.filename.startswith("libs/arm64-v8a/"):
                continue
            name = Path(info.filename).name
            if not name.startswith("lib"):
                continue
            data = archive.read(info)
            mode = info.external_attr >> 16
            if stat.S_ISLNK(mode):
                aliases[name] = data.decode("utf-8")
            elif data.startswith(b"\x7fELF"):
                libs[name] = data

        reject_compatibility_libraries(list(libs) + list(aliases))

        def resolve(name: str) -> str | None:
            seen: set[str] = set()
            while name in aliases:
                if name in seen:
                    return None
                seen.add(name)
                target = aliases[name]
                if "/" in target:
                    target = Path(target).name
                name = target
            return name if name in libs else None

        system_names = {
            child.name
            for directory in args.system_lib_dir
            if directory.is_dir()
            for child in directory.iterdir()
            if child.is_file() or child.is_symlink()
        }
        # Qt loads plugins on demand; they need complete dependencies too.
        pending = sorted(libs)
        visited: set[str] = set()
        missing: set[str] = set()

        with tempfile.TemporaryDirectory(prefix="snow-shot-hap-closure-") as temp:
            temp_dir = Path(temp)
            while pending:
                name = pending.pop()
                resolved = resolve(name)
                if resolved is None:
                    if name not in system_names:
                        missing.add(name)
                    continue
                if resolved in visited:
                    continue
                visited.add(resolved)
                extracted = temp_dir / resolved
                extracted.write_bytes(libs[resolved])
                needed = dynamic_needed(args.readelf, extracted)
                reject_compatibility_libraries(needed)
                pending.extend(needed)

        if missing:
            raise SystemExit(
                "HAP is missing non-platform runtime libraries:\n"
                + "\n".join(sorted(missing))
            )

    print(f"SNOW_SHOT_HAP_RUNTIME_CLOSURE_OK {len(visited)}")


if __name__ == "__main__":
    main()
