#!/usr/bin/env python3
"""Static checks for the formulae that ship tap-authored files from Resources/.

They fail in seconds, before a 20-minute formula build would find the same
mistake. See docs/hap-app-formulae.md for the conventions they enforce.

  1. A formula with a Resources/<name>/ directory lists every file of it, and
     every Resources/_shared file it uses, in a literal RESOURCE_FILES array,
     checks that they exist with `odie "missing tap resource: ..."`, and every
     listed path exists in the repository.
  2. All formulae pin the same electron-ohos release (url and sha256).
  3. Files taken from the tap checkout are copied with `cp`: the CI container
     mounts the tap read-only and Pathname#install moves its source
     (Errno::EACCES).

Usage: check-hap-formulae.py [--changed '["orca-app", ...]'] [--root DIR]
Without --changed every formula is checked. The electron pin check always looks
at every formula, because a drifting pin is a property of the set.
"""
import argparse
import json
import os
import re
import sys

PIN_BLOCK = re.compile(r'resource "electron-ohos" do\s*(.*?)\n  end', re.S)
LIST_BLOCK = re.compile(r"RESOURCE_FILES\s*=\s*%w\[(.*?)\]\.freeze", re.S)
TAP_INSTALL = re.compile(r"\.install\s+(?:tap_root|res)\b")

failures = []


def fail(path, message):
    failures.append((path, message))
    print(f"::error file={path}::{message}")


def formula_files(root):
    out = {}
    base = os.path.join(root, "Formula")
    for letter in sorted(os.listdir(base)):
        d = os.path.join(base, letter)
        if not os.path.isdir(d):
            continue
        for f in sorted(os.listdir(d)):
            if f.endswith(".rb"):
                out[f[:-3]] = os.path.join("Formula", letter, f)
    return out


def tree_files(root, rel):
    found = []
    top = os.path.join(root, rel)
    for dirpath, _, names in os.walk(top):
        for n in names:
            found.append(os.path.relpath(os.path.join(dirpath, n), root))
    return sorted(found)


def check_resources(root, name, rel, text):
    res_dir = f"Resources/{name}"
    if not os.path.isdir(os.path.join(root, res_dir)):
        return
    m = LIST_BLOCK.search(text)
    if not m:
        fail(rel, f"{res_dir}/ exists but the formula has no literal RESOURCE_FILES = %w[...].freeze list")
        return
    listed = m.group(1).split()
    if 'odie "missing tap resource' not in text:
        fail(rel, 'RESOURCE_FILES is not checked: add `odie "missing tap resource: #{file}" unless (tap_root/file).exist?` at the start of install')
    for path in listed:
        if not (path.startswith(res_dir + "/") or path.startswith("Resources/_shared/")):
            fail(rel, f"{path} is listed in RESOURCE_FILES but is neither under {res_dir}/ nor Resources/_shared/")
        if not os.path.isfile(os.path.join(root, path)):
            fail(rel, f"{path} is listed in RESOURCE_FILES but does not exist")
    for dup in sorted({p for p in listed if listed.count(p) > 1}):
        fail(rel, f"{dup} is listed more than once in RESOURCE_FILES")
    for path in tree_files(root, res_dir):
        if path not in listed:
            fail(rel, f"{path} is not listed in RESOURCE_FILES")


def check_tap_install(rel, text):
    for number, line in enumerate(text.splitlines(), 1):
        if line.strip().startswith("#"):
            continue
        if TAP_INSTALL.search(line):
            fail(rel, f"line {number}: files from the tap checkout must be copied with cp, not installed (the CI container mounts the tap read-only): {line.strip()}")


def check_pins(root, formulae):
    pins = {}
    for name, rel in formulae.items():
        text = open(os.path.join(root, rel), encoding="utf-8").read()
        m = PIN_BLOCK.search(text)
        if not m:
            continue
        url = re.search(r'url "([^"]+)"', m.group(1))
        sha = re.search(r'sha256 "([0-9a-f]{64})"', m.group(1))
        pins[name] = (url.group(1) if url else None, sha.group(1) if sha else None)
    groups = {}
    for name, pin in pins.items():
        groups.setdefault(pin, []).append(name)
    if len(groups) > 1:
        majority = max(groups.values(), key=len)
        for pin, names in groups.items():
            if names is majority:
                continue
            for name in names:
                fail(formulae[name], f"electron-ohos pin {pin[0]} ({(pin[1] or '')[:10]}) differs from the other formulae ({', '.join(sorted(majority))}); keep one release across all of them")
    return pins


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--changed", help="JSON list of formula names to check (default: all)")
    ap.add_argument("--root", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    args = ap.parse_args()
    root = os.path.abspath(args.root)

    formulae = formula_files(root)
    wanted = set(json.loads(args.changed)) if args.changed else set(formulae)
    checked = 0
    for name in sorted(wanted & set(formulae)):
        rel = formulae[name]
        text = open(os.path.join(root, rel), encoding="utf-8").read()
        check_resources(root, name, rel, text)
        check_tap_install(rel, text)
        checked += 1
    pins = check_pins(root, formulae)

    print(f"check-hap-formulae: {checked} formula(e) checked, {len(pins)} electron-ohos pin(s) compared, {len(failures)} problem(s)")
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as fh:
            fh.write("### check-hap-formulae\n")
            if failures:
                for path, message in failures:
                    fh.write(f"- ❌ `{path}`: {message}\n")
            else:
                fh.write(f"- ✅ {checked} formula(e) checked, {len(pins)} electron-ohos pin(s) identical\n")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
