#!/usr/bin/env python3
"""Keep local HAP packaging defaults aligned with the active production build."""

from pathlib import Path
import re

SCRIPT = Path(__file__).with_name("package-local-snow-shot.sh")
TEXT = SCRIPT.read_text(encoding="utf-8")

EXPECTED_DEFAULTS = {
    "stage": ("SNOW_SHOT_STAGE", "/data/storage/el2/base/cache/snow-shot-hap"),
    "build": ("SNOW_SHOT_BUILD_DIR", "/data/storage/el2/base/cache/snow-shot-build2"),
    "qt_sdk": ("SNOW_SHOT_QT_SDK", "/data/storage/el2/base/cache/qt-ohos-spike/qt-6.13.0-dev"),
}

for shell_variable, (environment_variable, expected) in EXPECTED_DEFAULTS.items():
    match = re.search(
        rf'^{shell_variable}="\$\{{{environment_variable}:-([^}}]+)\}}"$',
        TEXT,
        re.MULTILINE,
    )
    if match is None:
        raise AssertionError(f"missing environment-overridable default for {environment_variable}")
    if match.group(1) != expected:
        raise AssertionError(
            f"{environment_variable} defaults to {match.group(1)!r}, expected active path {expected!r}"
        )

print(f"LOCAL_HAP_PACKAGE_DEFAULTS_OK {len(EXPECTED_DEFAULTS)}")
