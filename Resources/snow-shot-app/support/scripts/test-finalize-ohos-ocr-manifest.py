#!/usr/bin/env python3
"""Verify the OCR descriptor fingerprints the runtime actually loaded by the HAP."""
import hashlib
import sys
sys.dont_write_bytecode = True
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

SPEC = importlib.util.spec_from_file_location(
    "finalizer", Path(__file__).with_name("finalize-ohos-ocr-manifest.py"))
FINALIZER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(FINALIZER)
RUNTIME = "libsnow_ocr_inprocess.so"
MANIFEST = "resources/rawfile/ocr/asset-manifest.json"


class FinalizeOcrManifestTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.hap = Path(self.temporary.name) / "app.hap"
        self.runtime = b"the final stripped cdylib bytes"

    def write_hap(self, name=RUNTIME):
        manifest = {"runtime": {"executable": RUNTIME,
                               "files": [{"name": name, "size": 0, "sha256": "stale"}]}}
        with zipfile.ZipFile(self.hap, "w") as archive:
            archive.writestr(MANIFEST, json.dumps(manifest))
            archive.writestr("libs/arm64-v8a/" + RUNTIME, self.runtime)
            archive.writestr("unchanged.txt", "keep")

    def test_hashes_actual_cdylib_after_packaging_without_a_standalone_worker(self):
        self.write_hap()
        FINALIZER.finalize(self.hap)
        with zipfile.ZipFile(self.hap) as archive:
            manifest = json.loads(archive.read(MANIFEST))
            descriptor, = manifest["runtime"]["files"]
            self.assertEqual(descriptor["size"], len(self.runtime))
            self.assertEqual(descriptor["sha256"], hashlib.sha256(self.runtime).hexdigest())
            self.assertEqual(archive.read("unchanged.txt"), b"keep")
            self.assertNotIn("libs/arm64-v8a/libsnow_ocr_process.so", archive.namelist())
        self.assertFalse(self.hap.with_suffix(".finalizing.hap").exists())

    def test_rejects_a_manifest_pointing_at_a_different_runtime(self):
        self.write_hap("wrong.so")
        before = self.hap.read_bytes()
        with self.assertRaisesRegex(ValueError, "runtime"):
            FINALIZER.finalize(self.hap)
        self.assertEqual(self.hap.read_bytes(), before)


if __name__ == "__main__":
    unittest.main()
