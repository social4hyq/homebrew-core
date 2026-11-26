#!/usr/bin/env python3
"""Add OHOS messages to the upstream Qt catalogs using their lookup keys."""

import argparse
import json
from pathlib import Path
import runpy
import xml.etree.ElementTree as ET


def merge(source, messages_path):
    catalogs = source / "i18n"
    upstream = runpy.run_path(str(source / "scripts/translation_catalogs.py"))
    locales = upstream["LOCALES"]
    _, owners = upstream["read_modules"](catalogs)
    messages = json.loads(messages_path.read_text(encoding="utf-8"))
    updates = {}
    for name, entries in messages.items():
        if name not in owners:
            raise ValueError(f"OHOS translation context has no upstream module: {name}")
        module = owners[name]
        for text, translations in entries.items():
            if translations.keys() != set(locales):
                raise ValueError(f"OHOS translation locales differ from upstream for {name}: {text}")

        for locale in locales:
            path = catalogs / module / f"snow_shot_{module}_{locale}.ts"
            if path not in updates:
                updates[path] = upstream["read_catalog"](path, locale)
            root = updates[path]
            context = next((item for item in root.findall("context") if item.findtext("name") == name), None)
            if context is None:
                context = ET.SubElement(root, "context")
                ET.SubElement(context, "name").text = name
            existing = {upstream["message_key"](name, item) for item in context.findall("message")}
            for text, translations in entries.items():
                if (name, text, "") not in existing:
                    message = ET.SubElement(context, "message")
                    ET.SubElement(message, "source").text = text
                    ET.SubElement(message, "translation").text = translations[locale]

    for path, root in updates.items():
        upstream["write_if_changed"](path, upstream["canonical_bytes"](root))
    upstream["check"](catalogs)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("messages", type=Path)
    args = parser.parse_args()
    merge(args.source, args.messages)
