#!/usr/bin/env python3
"""Unit tests for the immutable OHOS OCR payload staging helper."""

from __future__ import annotations

import hashlib
import sys
sys.dont_write_bytecode = True
import importlib.util
import json
import struct
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("stage-ohos-ocr-assets.py")
SPEC = importlib.util.spec_from_file_location("stage_ohos_ocr_assets", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
STAGER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(STAGER)


class StageOhosOcrAssetsTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.source_manifest = self.root / "source-manifest.json"
        self.runtime = self.root / "libsnow_ocr_inprocess.so"
        self.model_root = self.root / "source-models"
        self.output = self.root / "payload" / "assets" / "ocr"
        runtime_image = bytearray(64)
        runtime_image[:6] = b"\x7fELF\x02\x01"
        struct.pack_into("<H", runtime_image, 16, 3)
        struct.pack_into("<H", runtime_image, 18, 183)
        self.runtime_bytes = bytes(runtime_image)
        self.runtime.write_bytes(self.runtime_bytes)
        self.runtime.chmod(0o755)
        self.model_id = "ppocrv6-small-463ea9f"
        model_dir = self.model_root / self.model_id
        model_dir.mkdir(parents=True)
        self.model_bytes = {
            "PP-OCRv6_det_small.onnx": b"detector",
            "PP-OCRv6_rec_small.onnx": b"recognizer",
            "ppocrv6_dict.txt": b"dictionary",
        }
        model_files = []
        for name, content in self.model_bytes.items():
            (model_dir / name).write_bytes(content)
            model_files.append(
                {
                    "name": name,
                    "size": len(content),
                    "sha256": hashlib.sha256(content).hexdigest(),
                    "url": f"https://example.invalid/{name}",
                }
            )
        self.paragraph_id = "line2para-1-2-956253e"
        self.paragraph_name = "line2para_1_2-epoch12-signed-1.625.onnx"
        paragraph_dir = self.model_root / self.paragraph_id
        paragraph_dir.mkdir()
        self.paragraph_bytes = b"paragraph"
        (paragraph_dir / self.paragraph_name).write_bytes(self.paragraph_bytes)
        model_descriptors = [
            {
                "type": "extra_small",
                "id": "ppocrv6-tiny-cd609a1",
                "detector": "PP-OCRv6_det_tiny.onnx",
                "recognizer": "PP-OCRv6_rec_tiny.onnx",
                "dictionary": "ppocrv6_tiny_dict.txt",
                "files": [],
            },
            {
                "type": "small",
                "id": self.model_id,
                "detector": "PP-OCRv6_det_small.onnx",
                "recognizer": "PP-OCRv6_rec_small.onnx",
                "dictionary": "ppocrv6_dict.txt",
                "files": model_files,
            },
            {
                "type": "medium",
                "id": "ppocrv6-medium-f5063c6",
                "detector": "PP-OCRv6_det_medium.onnx",
                "recognizer": "PP-OCRv6_rec_medium.onnx",
                "dictionary": "ppocrv6_dict.txt",
                "files": [],
            },
        ]
        manifest = {
            "schema": 2,
            "default_model": "small",
            "runtime": {"version": "1.5.1", "platform": "windows-arm64"},
            "models": model_descriptors,
            "paragraph_model": {
                "id": self.paragraph_id,
                "files": [{
                    "name": self.paragraph_name,
                    "size": len(self.paragraph_bytes),
                    "sha256": hashlib.sha256(self.paragraph_bytes).hexdigest(),
                    "url": f"https://example.invalid/{self.paragraph_name}",
                }],
            },
        }
        self.source_manifest.write_text(json.dumps(manifest), encoding="utf-8")

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_stages_bundled_runtime_manifest_and_default_model(self) -> None:
        STAGER.stage(self.source_manifest, self.runtime, self.model_root, self.output)

        staged = json.loads((self.output / "asset-manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(staged["schema"], 3)
        self.assertEqual(staged["runtime"]["platform"], "openharmony-arm64")
        self.assertEqual(staged["runtime"]["delivery"], "bundled")
        self.assertEqual(staged["runtime"]["executable"], "libsnow_ocr_inprocess.so")
        self.assertEqual(staged["runtime"]["version"], "1.5.1")
        self.assertEqual(staged["runtime"]["protocol"], 8)
        self.assertEqual(staged["runtime"]["files"][0]["sha256"],
                         hashlib.sha256(self.runtime_bytes).hexdigest())
        for name, content in self.model_bytes.items():
            self.assertEqual((self.output / "models" / self.model_id / name).read_bytes(), content)
        paragraph = self.output / "models" / self.paragraph_id / self.paragraph_name
        self.assertEqual(paragraph.read_bytes(), self.paragraph_bytes)
        self.assertEqual(staged["paragraph_model"]["files"][0]["sha256"],
                         hashlib.sha256(self.paragraph_bytes).hexdigest())
        self.assertFalse((self.output / "models" / self.model_id / ".complete.json").exists())

    def test_rejects_model_payload_that_disagrees_with_manifest_hash(self) -> None:
        (self.model_root / self.model_id / "PP-OCRv6_det_small.onnx").write_bytes(b"tampered")
        with self.assertRaisesRegex(ValueError, "SHA-256"):
            STAGER.stage(self.source_manifest, self.runtime, self.model_root, self.output)

    def test_preflight_rejects_runtime_version_drift_without_a_built_runtime(self) -> None:
        self.runtime.unlink()
        STAGER.verify_models(self.source_manifest, self.model_root)
        manifest = json.loads(self.source_manifest.read_text(encoding="utf-8"))
        manifest["runtime"]["version"] = "1.5.2"
        self.source_manifest.write_text(json.dumps(manifest), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "1.5.2"):
            STAGER.verify_models(self.source_manifest, self.model_root)
        self.assertFalse(self.output.exists())

    def test_stages_shared_runtime_without_an_execute_permission_requirement(self) -> None:
        self.runtime.chmod(0o644)
        STAGER.stage(self.source_manifest, self.runtime, self.model_root, self.output)
        self.assertTrue((self.output / "asset-manifest.json").is_file())

    def test_rejects_standalone_executable_as_the_inprocess_runtime(self) -> None:
        executable = bytearray(self.runtime_bytes)
        struct.pack_into("<H", executable, 16, 2)
        self.runtime.write_bytes(executable)
        with self.assertRaisesRegex(ValueError, "shared library"):
            STAGER.stage(self.source_manifest, self.runtime, self.model_root, self.output)


if __name__ == "__main__":
    unittest.main()
