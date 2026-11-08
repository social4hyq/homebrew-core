#!/usr/bin/env python3
# Map changed formulae to their CI container images.
#
# Reads the detect job's build list (BUILD_JSON, e.g. '["foo","bar"]') and the
# OHOS_CI_IMAGE_OVERRIDES repo variable (a JSON object mapping formula name to
# image reference, for formulae that need a private/specialized CI image such
# as multica-ci), and writes `images=<json object>` to GITHUB_OUTPUT for the
# build job's per-matrix image lookup. Formulae without an override are
# omitted; the build job falls back to the default image for them.
import json
import os

build = json.loads(os.environ["BUILD_JSON"])
overrides = json.loads(os.environ.get("OVERRIDES") or "{}")

images = {name: overrides[name] for name in build
          if overrides.get(name)}

with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as fh:
    fh.write(f"images={json.dumps(images)}\n")

print(f"resolved images for {len(images)}/{len(build)} formula(e)")
