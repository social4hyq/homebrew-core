#!/usr/bin/env python3
"""Fetch @ohos-npm-ports native addon tarballs and extract them for the IDE HAP.

Downloads the pinned OHOS-native (NAPI, ABI-stable) .node modules that replace
the glibc addons the official VS Code fork cannot load on electron-ohos.
"""
import io
import json
import sys
import tarfile
import urllib.request
from pathlib import Path

# package -> (version, sha512-integrity from the npm registry)
PORTS = {
    "sqlite3": ("5.1.7-beta.0", "sha512-lz4i9kQpwXy+RiMjbgB0npI3scsyXhVeKF+yyvKlPNbG03il2W7EqbhESLXnTqy7wcCoigu/gtRChvcLaDepVw=="),
    "native-watchdog": ("1.4.2-beta.3", "sha512-MP7wv8axJPkItICNAmL4+1+E8xlDV7NRdLL08f+G7dRK3tEm3FhWlQobbDn4ryyGWkAHpX0ZkCGRacmRgKSS7Q=="),
    "parcel-watcher": ("2.6.0-beta.1", "sha512-MpVycYFUqw1MaDCcDkvHoS7wRkTzL5oDLsiTGWmjhMCQqAPoKJldY/Vjy8KDxjn8ddJWLS4Pg6aHXM/ADpkkCA=="),
}


def main():
    out = Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    import base64, hashlib
    for name, (version, integrity) in PORTS.items():
        pkg = f"@ohos-ports/{name}"
        enc = pkg.replace("/", "%2f").replace("@", "%40")
        url = f"https://registry.npmjs.org/{enc}/-/{name}-{version}.tgz"
        data = urllib.request.urlopen(url, timeout=90).read()
        algo, b64 = integrity.split("-", 1)
        digest = base64.b64encode(hashlib.new(algo, data).digest()).decode()
        if digest != b64:
            raise ValueError(f"integrity mismatch for {pkg}")
        dest = out / name
        if dest.exists():
            import shutil
            shutil.rmtree(dest)
        with tarfile.open(fileobj=io.BytesIO(data)) as t:
            t.extractall(dest, filter="data")
        print(f"fetched {pkg}@{version}")


if __name__ == "__main__":
    main()
