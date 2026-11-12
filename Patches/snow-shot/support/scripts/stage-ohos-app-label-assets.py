#!/usr/bin/env python3
"""Stage the canonical Snow Shot launcher label in each HAP locale."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

LABEL_RESOURCE = "QAbility_label"
LABEL_ASSET = Path("assets/app-labels.json")


def stage_labels(template: Path, stage: Path) -> None:
    labels = json.loads((template / LABEL_ASSET).read_text(encoding="utf-8"))
    if not isinstance(labels, dict) or not labels:
        raise ValueError(f"expected a locale-to-label object in {template / LABEL_ASSET}")
    if any(not isinstance(value, str) or not value.strip() for value in labels.values()):
        raise ValueError(f"application labels must be non-empty strings in {template / LABEL_ASSET}")
    if any(value.strip().lower() == "label" for value in labels.values()):
        raise ValueError(f"placeholder label is not a valid application name in {template / LABEL_ASSET}")

    updates: list[tuple[Path, str, dict[str, object]]] = []
    for locale, label in labels.items():
        resource = stage / "entry/src/main/resources" / locale / "element/string.json"
        document = json.loads(resource.read_text(encoding="utf-8"))
        entries = document.get("string")
        if not isinstance(entries, list):
            raise ValueError(f"missing string array in {resource}")
        matches = [entry for entry in entries if isinstance(entry, dict) and entry.get("name") == LABEL_RESOURCE]
        if len(matches) != 1:
            raise ValueError(
                f"expected exactly one {LABEL_RESOURCE} resource in {resource}, found {len(matches)}"
            )
        updates.append((resource, label, document))

    # Validate all locale inputs before writing any, to avoid a mixed-locale package stage.
    for resource, label, document in updates:
        for entry in document["string"]:
            if isinstance(entry, dict) and entry.get("name") == LABEL_RESOURCE:
                entry["value"] = label
        resource.write_text(json.dumps(document, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--template", required=True, type=Path)
    parser.add_argument("--stage", required=True, type=Path)
    arguments = parser.parse_args()
    try:
        stage_labels(arguments.template, arguments.stage)
    except (FileNotFoundError, json.JSONDecodeError, ValueError) as error:
        parser.error(str(error))
    print("STAGED_OFFICIAL_SNOW_SHOT_LABELS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
