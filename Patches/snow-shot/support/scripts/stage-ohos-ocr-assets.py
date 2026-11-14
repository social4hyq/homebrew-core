#!/usr/bin/env python3
"""Stage the bundled OHOS OCR runtime and verified default model payload."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import struct
from pathlib import Path
from typing import Any

RUNTIME_VERSION = "1.2.1"
RUNTIME_PROTOCOL = 7
PLATFORM = "openharmony-arm64"
RUNTIME_NAME = "libsnow_ocr_inprocess.so"
DEFAULT_MODEL = "small"


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _file_descriptor(path: Path, name: str) -> dict[str, Any]:
    return {"name": name, "size": path.stat().st_size, "sha256": _sha256(path)}


def _verified_model_file(model_root: Path, model_id: str, item: dict[str, Any]) -> Path:
    name = item.get("name")
    size = item.get("size")
    expected_hash = item.get("sha256")
    if not isinstance(name, str) or Path(name).name != name:
        raise ValueError("model manifest contains an unsafe filename")
    if not isinstance(size, int) or size < 0 or not isinstance(expected_hash, str):
        raise ValueError(f"model manifest has invalid size or SHA-256 for {name}")
    path = model_root / model_id / name
    if not path.is_file() or path.is_symlink():
        raise ValueError(f"required model file is missing or not a regular file: {path}")
    if path.stat().st_size != size or _sha256(path) != expected_hash:
        raise ValueError(f"model file size or SHA-256 does not match manifest: {name}")
    return path


def stage(source_manifest: Path, runtime: Path, model_root: Path, output_root: Path) -> None:
    manifest = json.loads(source_manifest.read_text(encoding="utf-8"))
    if manifest.get("schema") != 2 or manifest.get("default_model") != DEFAULT_MODEL:
        raise ValueError("source asset manifest is not the supported Windows schema-2 contract")
    source_runtime = manifest.get("runtime")
    if not isinstance(source_runtime, dict) or source_runtime.get("version") != RUNTIME_VERSION:
        raise ValueError("source asset manifest runtime version is incompatible")
    models = manifest.get("models")
    if not isinstance(models, list) or len(models) != 3:
        raise ValueError("source manifest must retain all three OCR model descriptors")
    small_models = [item for item in models if item.get("type") == DEFAULT_MODEL]
    if len(small_models) != 1:
        raise ValueError("source manifest must contain exactly one default Small model")
    small = small_models[0]
    model_id = small.get("id")
    if not isinstance(model_id, str) or not model_id:
        raise ValueError("default Small model descriptor has no cache ID")
    if runtime.is_symlink() or not runtime.is_file():
        raise ValueError("OCR runtime must be a regular file")
    runtime = runtime.resolve(strict=True)
    runtime_bytes = runtime.read_bytes()
    if len(runtime_bytes) < 20 or runtime_bytes[:6] != b"\x7fELF\x02\x01":
        raise ValueError("OCR runtime is not a little-endian ELF64 shared library")
    if struct.unpack_from("<H", runtime_bytes, 18)[0] != 183:
        raise ValueError("OCR runtime is not an AArch64 shared library")
    if struct.unpack_from("<H", runtime_bytes, 16)[0] != 3:
        raise ValueError("OCR runtime is not an ELF shared library")
    files = small.get("files")
    if not isinstance(files, list) or len(files) != 3:
        raise ValueError("Small model descriptor must contain detector, recognizer, and dictionary")
    for field in ("detector", "recognizer", "dictionary"):
        if not isinstance(small.get(field), str):
            raise ValueError(f"Small model descriptor is missing {field}")
    names = {item.get("name") for item in files if isinstance(item, dict)}
    if names != {small["detector"], small["recognizer"], small["dictionary"]}:
        raise ValueError("Small model role names do not match its asset file descriptors")
    verified_files = [_verified_model_file(model_root, model_id, item) for item in files]

    if output_root.exists():
        if output_root.is_symlink() or not output_root.is_dir():
            raise ValueError("OCR output root must be a real directory")
        shutil.rmtree(output_root)
    model_output = output_root / "models" / model_id
    model_output.mkdir(parents=True)
    for path in verified_files:
        shutil.copyfile(path, model_output / path.name)
    manifest["schema"] = 3
    manifest["runtime"] = {
        "version": RUNTIME_VERSION,
        "platform": PLATFORM,
        "delivery": "bundled",
        "protocol": RUNTIME_PROTOCOL,
        "executable": RUNTIME_NAME,
        "files": [_file_descriptor(runtime, RUNTIME_NAME)],
    }
    (output_root / "asset-manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, separators=(",", ":")), encoding="utf-8"
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-manifest", type=Path, required=True)
    parser.add_argument("--runtime", type=Path, required=True)
    parser.add_argument("--model-root", type=Path, required=True)
    parser.add_argument("--output-root", type=Path, required=True)
    args = parser.parse_args()
    stage(args.source_manifest, args.runtime, args.model_root, args.output_root)
    print(f"OCR_ASSETS_STAGED {args.output_root}")


if __name__ == "__main__":
    main()
