#!/usr/bin/env python3
"""Project L0 contract schemas into a formula's Resources/<formula>/schemas/v1/.
Same-source projection; never hand-duplicate. Stdlib only.

Usage: project-ohos-app-schemas.py --root DIR --formula NAME \
         --groups g1,g2 --out TAP_ROOT
  groups: descriptor | l2 | plugins | sign | device
"""
import argparse
import hashlib
import shutil
import sys
from pathlib import Path

GROUP_DIRS = {
    "descriptor": "descriptor",
    "l2": "l2",
    "plugins": "plugins",
    "sign": "sign",
    "device": "device",
}

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True)
    ap.add_argument("--formula", required=True)
    ap.add_argument("--groups", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    root = Path(args.root)
    tap = Path(args.out)
    formula = args.formula
    if not root.is_dir() or not tap.is_dir():
        print("bad root/out dir", file=sys.stderr); return 2
    if not all(c.isalnum() or c in "@+._-" for c in formula):
        print("bad formula name", file=sys.stderr); return 2

    dest = tap / "Resources" / formula / "schemas" / "v1"
    dest.mkdir(parents=True, exist_ok=True)
    groups = [g.strip() for g in args.groups.split(",") if g.strip()]
    count = 0
    for g in groups:
        sub = GROUP_DIRS.get(g)
        if sub is None:
            print(f"unknown group: {g}", file=sys.stderr); return 2
        src = root / sub
        if not src.is_dir():
            print(f"missing contract dir: {src}", file=sys.stderr); return 1
        for f in sorted(src.glob("*.schema.json")):
            shutil.copy2(f, dest / f.name)
            count += 1

    # 合同根指纹（errors.json / framing.md / 所有 schema）随投影写入。
    lines = []
    for f in sorted(root.rglob("*")):
        if f.is_file() and (f.name.endswith(".schema.json") or f.name in ("errors.json", "framing.md")):
            h = hashlib.sha256(f.read_bytes()).hexdigest()
            lines.append(f"{h}  {f.relative_to(root)}")
    (dest / "CONTRACT.sha256").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"projected {count} schema(s) into {dest} (formula={formula} groups={args.groups})")
    return 0

if __name__ == "__main__":
    sys.exit(main())
