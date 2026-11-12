#!/usr/bin/env python3
"""Stage the official Snow Shot icon in all HarmonyOS HAP icon slots."""

from __future__ import annotations

import argparse
import re
import shutil
import struct
from pathlib import Path

ICON_ASSETS = {
    "AppScope/resources/base/media/app_icon.png": (512, 512),
    "entry/src/main/resources/base/media/foreground.png": (288, 288),
    "entry/src/main/resources/base/media/background.png": (288, 288),
    "entry/src/main/resources/base/media/startIcon.png": (144, 144),
}
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as stream:
        header = stream.read(24)
    if len(header) != 24 or header[:8] != PNG_SIGNATURE or header[12:16] != b"IHDR":
        raise ValueError(f"not a valid PNG with an IHDR header: {path}")
    return struct.unpack(">II", header[16:24])


def stage_icons(template: Path, stage: Path) -> None:
    validated: list[tuple[Path, Path]] = []
    for relative_path, expected_size in ICON_ASSETS.items():
        source = template / relative_path
        if not source.is_file():
            raise FileNotFoundError(f"missing official HAP icon asset: {source}")
        actual_size = png_dimensions(source)
        if actual_size != expected_size:
            raise ValueError(
                f"wrong dimensions for {source}: expected {expected_size}, got {actual_size}"
            )
        validated.append((source, stage / relative_path))

    module_manifest = stage / "entry/src/main/module.json5"
    if not module_manifest.is_file():
        raise FileNotFoundError(f"missing staged entry module manifest: {module_manifest}")
    manifest = module_manifest.read_text(encoding="utf-8")
    icon_reference = re.compile(
        r'("icon"\s*:\s*)[\'"]\$media:(layered_image|app_icon)[\'"]'
    )
    references = list(icon_reference.finditer(manifest))
    if len(references) != 1:
        raise ValueError(
            "expected exactly one entry ability icon reference to $media:layered_image "
            f"or $media:app_icon in {module_manifest}, found {len(references)}"
        )
    if references[0].group(2) == "layered_image":
        manifest = icon_reference.sub(r'\1"$media:app_icon"', manifest, count=1)

    # Validate every input before changing the destination, so a partial or stale
    # icon set can never leave a mixed-brand package stage.
    for source, destination in validated:
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)
    module_manifest.write_text(manifest, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--template", required=True, type=Path)
    parser.add_argument("--stage", required=True, type=Path)
    arguments = parser.parse_args()
    try:
        stage_icons(arguments.template, arguments.stage)
    except (FileNotFoundError, ValueError) as error:
        parser.error(str(error))
    print(f"STAGED_OFFICIAL_SNOW_SHOT_ICONS {len(ICON_ASSETS)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
