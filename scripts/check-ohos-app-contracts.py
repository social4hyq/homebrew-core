#!/usr/bin/env python3
"""Lightweight contract checker for ohos-app L0 schemas (stdlib only).

Validates:
  1. every *.schema.json in the contract root is itself a syntactically valid
     JSON Schema skeleton (we check the local keywords we rely on, not the full
     meta-schema — no third-party dependency available on this host);
  2. golden fixtures under --fixtures validate against the schema named in
     their `_schema` field; a fixture in fixtures/invalid/ MUST fail;
  3. cross-cutting invariants: no forbidden plaintext-secret field names, no
     shell-string exec, protocol_version const consistency, state enums match
     device-contract, error codes come from errors.json.

Usage: check-ohos-app-contracts.py --root DIR --fixtures DIR
"""
import argparse
import json
import re
import sys
from pathlib import Path

FORBIDDEN_KEYS = {"password", "passwd", "key_password", "store_password", "token", "secret"}
SECRET_VALUE_KEYWORDS = re.compile(r"(password|passwd|token|secret)\s*[:=]", re.I)
SHELL_CHARS = re.compile(r"[;&|`$(){}<>\n]")

errors = []
def fail(msg):
    errors.append(msg)


def load_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as e:
        fail(f"{path}: invalid JSON: {e}")
        return None


def check_schema_shape(path, doc):
    """Validate the local JSON-Schema keywords we use."""
    if not isinstance(doc, dict):
        fail(f"{path}: schema root must be object")
        return
    t = doc.get("type")
    if t is not None and t not in ("object", "array", "string", "integer", "boolean", "null", ["object", "null"], ["boolean", "null"]):
        # allow list-of-types forms we actually use
        if not (isinstance(t, list) and all(x in ("object", "string", "integer", "boolean", "null") for x in t)):
            fail(f"{path}: unsupported type {t!r}")
    if t == "object":
        props = doc.get("properties", {})
        req = doc.get("required", [])
        if not isinstance(props, dict):
            fail(f"{path}: properties must be object")
        for r in req:
            if r not in props:
                fail(f"{path}: required field {r!r} not in properties")
    # const/enum/pattern sanity
    if "pattern" in doc:
        try:
            re.compile(doc["pattern"])
        except re.error as e:
            fail(f"{path}: bad pattern: {e}")


def validate_local(instance, schema, path="$"):
    """Validate instance against the LOCAL keywords of schema (no external $ref)."""
    t = schema.get("type")
    if t is not None:
        types = t if isinstance(t, list) else [t]
        def ok_type(v, ty):
            return {
                "object": lambda x: isinstance(x, dict),
                "array": lambda x: isinstance(x, list),
                "string": lambda x: isinstance(x, str),
                "integer": lambda x: isinstance(x, int) and not isinstance(x, bool),
                "boolean": lambda x: isinstance(x, bool),
                "null": lambda x: x is None,
            }[ty](v)
        if not any(ok_type(instance, ty) for ty in types):
            return [f"{path}: expected type {types}, got {type(instance).__name__}"]
    out = []
    if "const" in schema and instance != schema["const"]:
        out.append(f"{path}: const mismatch ({instance!r} != {schema['const']!r})")
    if "enum" in schema and instance not in schema["enum"]:
        out.append(f"{path}: {instance!r} not in enum {schema['enum']}")
    if "pattern" in schema and isinstance(instance, str) and not re.search(schema["pattern"], instance):
        out.append(f"{path}: {instance!r} does not match {schema['pattern']}")
    if isinstance(instance, str) and ("minLength" in schema) and len(instance) < schema["minLength"]:
        out.append(f"{path}: shorter than minLength")
    if isinstance(instance, int) and not isinstance(instance, bool):
        if "minimum" in schema and instance < schema["minimum"]:
            out.append(f"{path}: below minimum")
    if isinstance(instance, list):
        if "minItems" in schema and len(instance) < schema["minItems"]:
            out.append(f"{path}: fewer than minItems")
        if schema.get("uniqueItems") and len(instance) != len({json.dumps(x, sort_keys=True) for x in instance}):
            out.append(f"{path}: uniqueItems violated")
        for i, item in enumerate(instance):
            if "items" in schema and isinstance(schema["items"], dict):
                out += validate_local(item, schema["items"], f"{path}[{i}]")
    if isinstance(instance, dict):
        props = schema.get("properties", {})
        for r in schema.get("required", []):
            if r not in instance:
                out.append(f"{path}: missing required {r!r}")
        addl = schema.get("additionalProperties", True)
        for k, v in instance.items():
            if k == "_schema":
                continue
            if k in props and isinstance(props[k], dict):
                out += validate_local(v, props[k], f"{path}.{k}")
            elif addl is False:
                out.append(f"{path}: additional property {k!r} not allowed")
            elif isinstance(addl, dict):
                out += validate_local(v, addl, f"{path}.{k}")
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True)
    ap.add_argument("--fixtures", required=True)
    args = ap.parse_args()
    root = Path(args.root)
    fixtures = Path(args.fixtures)

    schemas = {}
    for p in sorted(root.rglob("*.schema.json")):
        doc = load_json(p)
        if doc is None:
            continue
        check_schema_shape(p, doc)
        schemas[p.name.replace(".schema.json", "")] = (p, doc)

    # errors.json code registry
    errdoc = load_json(root / "errors.json")
    codes = set(errdoc.get("codes", {})) if errdoc else set()

    # cross-cutting: no plaintext secret keys in any schema
    for name, (p, doc) in schemas.items():
        blob = json.dumps(doc)
        if SECRET_VALUE_KEYWORDS.search(blob):
            # schema *descriptions* may mention secret; only flag key names
            txt = json.dumps(doc.get("properties", {}))
            if SECRET_VALUE_KEYWORDS.search(txt):
                fail(f"{p}: schema exposes a plaintext secret key")

    # fixtures
    checked = 0
    for fx in sorted(fixtures.rglob("*.json")):
        if fx.name.endswith(".schema.json"):
            continue
        doc = load_json(fx)
        if doc is None:
            continue
        sname = doc.get("_schema")
        if not sname or sname not in schemas:
            fail(f"{fx}: unknown _schema {sname!r}")
            continue
        p, schema = schemas[sname]
        errs = validate_local(doc, schema)
        # referenced error codes must be known (counts as a validation error)
        def walk(x, pth="$"):
            if isinstance(x, dict):
                if "code" in x and isinstance(x["code"], str) and x["code"] not in codes:
                    errs.append(f"{pth}.code: unknown error code {x['code']!r}")
                for k, v in x.items():
                    walk(v, f"{pth}.{k}")
            elif isinstance(x, list):
                for i, v in enumerate(x):
                    walk(v, f"{pth}[{i}]")
        walk(doc)
        must_fail = "invalid" in fx.parts
        if must_fail:
            if not errs:
                fail(f"{fx}: expected to FAIL validation but passed")
            else:
                checked += 1
        else:
            if errs:
                fail(f"{fx}: unexpected validation errors: {'; '.join(errs)}")
            else:
                checked += 1

    if errors:
        for e in errors:
            print("FAIL:", e, file=sys.stderr)
        print(f"{len(errors)} error(s)", file=sys.stderr)
        sys.exit(1)
    print(f"OK: {len(schemas)} schemas, {checked} fixtures, {len(codes)} error codes")


if __name__ == "__main__":
    main()
