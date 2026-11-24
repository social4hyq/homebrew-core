#!/usr/bin/env python3
"""OHOS compatibility patches for the official Antigravity IDE (VS Code fork).

The vendor app tree is closed source and ships several linux-arm64 glibc
.node addons that cannot be dlopen'd on OHOS musl, plus it assumes a Linux
platform / full Electron API. This module rewrites the extracted vendor tree
at install time (never in the bottle) using the device-verified approach:

  * use real OHOS-native .node modules from @ohos-npm-ports (NAPI, ABI-stable)
    placed in the HAP's libs/ directory (the only namespace where dlopen works)
  * stub the remaining addons with pure JS
  * present platform "linux" to VS Code via globalThis.vscode.process
  * relax DI strict mode and guard an Electron API absent on OHOS

Usage: patch_vendor(app_root, native_dir) where native_dir contains the
extracted @ohos-npm-ports packages (sqlite3/node-pty/etc.).
"""
import json
import shutil
from pathlib import Path

MARKER = ".ohos-compat-applied"

# OHOS-native addons from @ohos-npm-ports. (relative path in tgz, target name)
NATIVE = {
    "build/Release/node_sqlite3.node": "sqlite3.node",
    "build/Release/watchdog.node": "watchdog.node",
    "build/Release/watcher.node": "watcher.node",
}

# Pure-JS replacements for addons with no usable OHOS port / not needed to boot.
STUBS = {
    "node_modules/@vscode/spdlog/index.js": """const fs=require('fs');
class Logger{constructor(t,n,f){this.f=f;}info(...a){this._w('I',a);}warn(...a){this._w('W',a);}error(...a){this._w('E',a);}debug(){}critical(...a){this._w('C',a);}trace(){}flush(){}setLevel(){}setPattern(){}clearFormatters(){}drop(){}dispose(){} _w(l,a){try{fs.appendFileSync(this.f,l+' '+a.map(String).join(' ')+'\\n');}catch(e){}}}
exports.version='ohos-stub';exports.setLevel=()=>{};exports.setFlushOn=()=>{};exports.Logger=Logger;
exports.createRotatingLogger=async(n,f)=>new Logger('r',n,f);exports.createAsyncRotatingLogger=async(n,f)=>new Logger('ra',n,f);
""",
    "node_modules/kerberos/lib/kerberos.js": """exports.version='ohos-stub';
class Kerberos{authGSSAPI(){return Promise.reject(new Error('kerberos unavailable on OHOS'));}authGSSAPIServer(){return Promise.reject(new Error('kerberos unavailable on OHOS'));}}
exports.Kerberos=Kerberos;
""",
    "node_modules/@vscode/policy-watcher/index.js": "exports.createWatcher=function(){return {dispose(){},onDidChange:()=>({dispose(){}})};};\n",
}

# native keymap stub (VS Code calls getCurrentKeyboardLayout / onDidChangeKeyboardLayout)
KEYMAP_STUB = """// CJS with named exports so ESM import() can see each name (cjs-module-lexer).
exports.getCurrentKeyboardLayout = () => ({ layout: 'us', lang: 'en' });
exports.getKeyboardLayouts = () => [{ layout: 'us', lang: 'en' }];
exports.getKeyMap = () => ({});
exports.getKeyMapSync = () => ({});
exports.onDidChangeKeyboardLayout = () => ({ dispose() {} });
exports.isISOKeyboard = () => false;
"""

STRICT_OLD = "_throwIfStrict(t,n){if(n&&console.warn(t),this._strict)throw new Error(t)}"
STRICT_NEW = "_throwIfStrict(t,n){console.warn(t)}"
TITLEBAR_OLD = "n.setTitleBarOverlay({color:"
TITLEBAR_NEW = 'typeof n.setTitleBarOverlay==="function"&&n.setTitleBarOverlay({color:'
# updateService is not registered on this build; guard its IPC event access so
# the uncaught onStateChange exception does not break the main process.
UPDATE_LISTEN_OLD = 'case"onStateChange":return this.service.onStateChange'
UPDATE_LISTEN_NEW = 'case"onStateChange":return this.service?.onStateChange||(()=>({dispose(){}}))'
# The HAP sandbox has no login shell (/bin/bash exit 127); VS Code's
# resolveShellEnv() spawns one and fails. We already inject host PATH/HOME via
# the wrapper, so skip shell environment resolution entirely.
SHELLENV_OLD = 'n["force-disable-user-env"]?(t.trace("resolveShellEnv()'
SHELLENV_NEW = 'true?(t.trace("resolveShellEnv()'
# updateService is not registered in this OHOS build; the IPC shim's call()
# dereferences this.service.* which is undefined. Return safe values.
UPDATESVC_CALL_OLD = 'call(e,t,n){switch(t){case"checkForUpdates":return this.service.checkForUpdates(n);case"downloadUpdate":return this.service.downloadUpdate();case"applyUpdate":return this.service.applyUpdate();case"quitAndInstall":return this.service.quitAndInstall();case"_getInitialState":return Promise.resolve(this.service.state);case"isLatestVersion":return this.service.isLatestVersion();case"_applySpecificUpdate":return this.service._applySpecificUpdate(n)}'
UPDATESVC_CALL_NEW = 'call(e,t,n){const s=this.service||{state:{type:"idle"},checkForUpdates:()=>Promise.resolve(),downloadUpdate:()=>Promise.resolve(),applyUpdate:()=>Promise.resolve(),quitAndInstall:()=>Promise.resolve(),isLatestVersion:()=>Promise.resolve(false),_applySpecificUpdate:()=>Promise.resolve()};switch(t){case"checkForUpdates":return s.checkForUpdates(n);case"downloadUpdate":return s.downloadUpdate();case"applyUpdate":return s.applyUpdate();case"quitAndInstall":return s.quitAndInstall();case"_getInitialState":return Promise.resolve(s.state);case"isLatestVersion":return s.isLatestVersion();case"_applySpecificUpdate":return s._applySpecificUpdate(n)}'
# Redirect the sqlite3 binding to the OHOS-native module in the HAP libs dir.
BINDING_OLD = "require('../build/Release/vscode-sqlite3.node')"
BINDING_NEW = 'require("/data/storage/el1/bundle/libs/arm64/sqlite3.node")'


def patch_vendor(app_root: Path, native_dir: Path | None = None) -> None:
    """Apply compatibility rewrites to an extracted vendor app tree.

    app_root: the extracted 'resources/app' directory (contains out/main.js,
              node_modules/, ...).
    native_dir: directory holding extracted @ohos-npm-ports packages, each in
                its own subdirectory. Native .node files are copied into
                app_root/ohos-native/ so the assembler can place them into the
                HAP's libs/ directory.
    """
    marker = app_root / MARKER
    if marker.exists():
        return

    # 1. copy the OHOS-native .node addons to a staging dir inside the vendor
    if native_dir and native_dir.is_dir():
        out = app_root / "ohos-native"
        out.mkdir(exist_ok=True)
        for rel, target in NATIVE.items():
            for pkg in native_dir.iterdir():
                candidate = pkg / "package" / rel
                if candidate.is_file():
                    shutil.copy2(candidate, out / target)
                    break

    # 2. pure-JS stubs
    for rel, content in STUBS.items():
        target = app_root / rel
        if target.is_file():
            target.write_text(content, encoding="utf-8")

    # 3. native-keymap stub (its .node cannot load; VS Code needs these methods)
    km = app_root / "node_modules/native-keymap/index.js"
    if km.is_file():
        km.write_text(KEYMAP_STUB, encoding="utf-8")

    # 4. redirect the sqlite3 binding to the OHOS-native module
    bind = app_root / "node_modules/@vscode/sqlite3/lib/sqlite3-binding.js"
    if bind.is_file():
        s = bind.read_text(encoding="utf-8")
        if BINDING_OLD in s:
            bind.write_text(s.replace(BINDING_OLD, BINDING_NEW), encoding="utf-8")

    # 5. main.js patches
    main = app_root / "out/main.js"
    if main.is_file():
        s = main.read_text(encoding="utf-8")
        s = s.replace(STRICT_OLD, STRICT_NEW)
        s = s.replace(TITLEBAR_OLD, TITLEBAR_NEW)
        s = s.replace(BINDING_OLD, BINDING_NEW)
        s = s.replace(UPDATE_LISTEN_OLD, UPDATE_LISTEN_NEW)
        s = s.replace(SHELLENV_OLD, SHELLENV_NEW)
        s = s.replace(UPDATESVC_CALL_OLD, UPDATESVC_CALL_NEW)
        main.write_text(s, encoding="utf-8")

    # The extension host runs in a separate utility process whose entryPoint is
    # this file. It never sees our bootstrap platform proxy, so inject a linux
    # platform view via globalThis.vscode.process here too.
    eh = app_root / "out/vs/workbench/api/node/extensionHostProcess.js"
    if eh.is_file():
        e = eh.read_text(encoding="utf-8")
        if "globalThis.vscode.process" not in e:
            inject = (';try{Object.defineProperty(process,"platform",'
                      '{value:"linux",configurable:true});}catch(_){}'
                      'globalThis.vscode=globalThis.vscode||{};'
                      'globalThis.vscode.process=new Proxy(process,'
                      '{get(t,k){if(k==="platform")return"linux";'
                      'const v=t[k];return typeof v==="function"?v.bind(t):v;}});')
            eh.write_text(inject + e, encoding="utf-8")
            print("ohos-compat: extension host platform proxy injected")

    marker.write_text(json.dumps({
        "native": list(NATIVE.values()), "stubs": list(STUBS),
    }), encoding="utf-8")
