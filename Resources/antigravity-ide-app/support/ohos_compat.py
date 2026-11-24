#!/usr/bin/env python3
"""OHOS compatibility patches for the official Antigravity IDE (VS Code fork).

The vendor app tree is closed source and ships native .node addons built for
linux-arm64 glibc. electron-ohos uses musl, so those addons cannot be dlopen'd.
This module rewrites the extracted vendor tree at install time (never in the
bottle) so the workbench can boot:

  * stub the addons that are unconditionally require()'d at startup
  * make VS Code see platform "linux" without disturbing electron-ohos
  * relax the DI strict check and guard an Electron API absent on OHOS

All rewrites are best-effort and idempotent: a marker file records completion
so a reinstall over an already-patched tree is a no-op.
"""
import json
from pathlib import Path

MARKER = ".ohos-compat-applied"

# Pure-JS replacements for native addons that are require()'d unconditionally
# during VS Code startup. Paths are relative to the vendor app root.
STUBS = {
    "node_modules/@vscode/spdlog/index.js": """const fs=require('fs');
class Logger{constructor(t,n,f){this.f=f;}info(...a){this._w('I',a);}warn(...a){this._w('W',a);}error(...a){this._w('E',a);}debug(){}critical(...a){this._w('C',a);}trace(){}flush(){}setLevel(){}setPattern(){}clearFormatters(){}drop(){}dispose(){} _w(l,a){try{fs.appendFileSync(this.f,l+' '+a.map(String).join(' ')+'\\n');}catch(e){}}}
exports.version='ohos-stub';exports.setLevel=()=>{};exports.setFlushOn=()=>{};exports.Logger=Logger;
exports.createRotatingLogger=async(n,f)=>new Logger('r',n,f);exports.createAsyncRotatingLogger=async(n,f)=>new Logger('ra',n,f);
""",
    "node_modules/@vscode/sqlite3/lib/sqlite3-binding.js": """// OHOS stub: native sqlite3.node cannot load on musl. State is not persisted.
class Statement{constructor(sql){this.sql=sql;}run(){return this;}get(){return undefined;}all(){return [];}each(){return this;}finalize(){return this;}reset(){return this;}}
class Database{constructor(path,cb){this.path=path;if(typeof cb==='function')setTimeout(cb,0);}run(sql,...a){const cb=typeof a[a.length-1]==='function'?a.pop():undefined;if(cb)setTimeout(()=>cb(null),0);return this;}get(sql,...a){const cb=typeof a[a.length-1]==='function'?a.pop():undefined;if(cb)setTimeout(()=>cb(null,undefined),0);}all(sql,...a){const cb=typeof a[a.length-1]==='function'?a.pop():undefined;if(cb)setTimeout(()=>cb(null,[]),0);}each(){}prepare(sql,cb){const s=new Statement(sql);if(cb)setTimeout(()=>cb(null,s),0);return s;}exec(sql,cb){if(cb)setTimeout(()=>cb(null),0);return this;}close(cb){if(cb)setTimeout(()=>cb(null),0);}serialize(){return this;}parallelize(){return this;}interrupt(){}}
exports.Database=Database;exports.Statement=Statement;exports.OPEN_READONLY=1;exports.OPEN_READWRITE=2;exports.OPEN_CREATE=4;exports.verbose=()=>exports;
""",
    "node_modules/kerberos/lib/kerberos.js": """exports.version='ohos-stub';
class Kerberos{authGSSAPI(){return Promise.reject(new Error('kerberos unavailable on OHOS'));}authGSSAPIServer(){return Promise.reject(new Error('kerberos unavailable on OHOS'));}}
exports.Kerberos=Kerberos;
""",
    "node_modules/native-watchdog/index.js": "exports.start=function(){};exports.kill=function(){};\n",
    "node_modules/@vscode/policy-watcher/index.js": "exports.createWatcher=function(){return {dispose(){},onDidChange:()=>({dispose(){}})};};\n",
}

# main.js exact replacements (verified against the pinned 2.8.0 build).
STRICT_OLD = "_throwIfStrict(t,n){if(n&&console.warn(t),this._strict)throw new Error(t)}"
STRICT_NEW = "_throwIfStrict(t,n){console.warn(t)}"
TITLEBAR_OLD = "n.setTitleBarOverlay({color:"
TITLEBAR_NEW = 'typeof n.setTitleBarOverlay==="function"&&n.setTitleBarOverlay({color:'


def patch_bootstrap(path: Path) -> None:
    """Make VS Code read platform 'linux' via globalThis.vscode.process, leaving
    the real process.platform (openharmony) intact for electron-ohos."""
    src = path.read_text(encoding="utf-8")
    if "globalThis.vscode.process" in src:
        return
    inject = """// OHOS: present a linux platform to VS Code without touching electron-ohos.
const __ohosRealProcess = process;
const __ohosPlatformProxy = new Proxy(__ohosRealProcess, {
  get(t, k) {
    if (k === 'platform') return 'linux';
    const v = t[k];
    return typeof v === 'function' ? v.bind(t) : v;
  }
});
globalThis.vscode = globalThis.vscode || {};
globalThis.vscode.process = __ohosPlatformProxy;
"""
    # insert after the leading comment block, before first require
    lines = src.split("\n")
    insert_at = 0
    for i, line in enumerate(lines):
        if line.lstrip().startswith(("const ", "import ", "//")):
            if not line.lstrip().startswith("//"):
                insert_at = i
                break
    lines.insert(insert_at, inject)
    path.write_text("\n".join(lines), encoding="utf-8")


def patch_vendor(app_root: Path) -> None:
    """Apply all compatibility rewrites to an extracted vendor app tree."""
    marker = app_root / MARKER
    if marker.exists():
        return

    for rel, content in STUBS.items():
        target = app_root / rel
        if not target.is_file():
            continue  # optional module in this build
        target.write_text(content, encoding="utf-8")

    main = app_root / "out/main.js"
    if main.is_file():
        s = main.read_text(encoding="utf-8")
        n = s.count(STRICT_OLD)
        s = s.replace(STRICT_OLD, STRICT_NEW)
        m = s.count(TITLEBAR_OLD)
        s = s.replace(TITLEBAR_OLD, TITLEBAR_NEW)
        main.write_text(s, encoding="utf-8")
        print(f"ohos-compat: main.js strict x{n}, titlebar x{m}")

    marker.write_text(json.dumps({"stubs": list(STUBS)}), encoding="utf-8")
