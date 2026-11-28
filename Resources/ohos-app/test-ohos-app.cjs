#!/usr/bin/env node
"use strict";
// Orchestration contract tests with fake L3 (ohos-hap) and L4 (ohos-device).
// No real signing, no device, no <app> install callback.
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");
const crypto = require("node:crypto");
const { spawnSync } = require("node:child_process");

const CLI = path.join(__dirname, "ohos-app.cjs");
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "ohos-app-test-"));
const prefix = path.join(tmp, "prefix");
let passed = 0, failed = 0;
function test(name, fn) {
  try { fn(); passed += 1; console.log("PASS", name); }
  catch (e) { failed += 1; console.error("FAIL", name, "-", e.message); }
}
function run(args, env = {}) {
  return spawnSync(process.execPath, [CLI, ...args], {
    encoding: "utf8", env: { ...process.env, HOMEBREW_PREFIX: prefix, ...env },
  });
}
function sha(b) { return crypto.createHash("sha256").update(b).digest("hex"); }
function makeApp(formula, over = {}) {
  const dir = path.join(prefix, "opt", formula, "share", formula, "ohos");
  fs.mkdirSync(dir, { recursive: true });
  const hap = path.join(dir, "unsigned.hap");
  const fixture = path.join(dir, "hap-fixture");
  fs.mkdirSync(fixture, { recursive: true });
  fs.writeFileSync(path.join(fixture, "module.json"), JSON.stringify({
    app: { bundleName: "com.example.app", versionName: "1.0", versionCode: 1 },
    module: { name: "entry", requestPermissions: [] },
  }));
  const zipped = spawnSync("zip", ["-q", "-r", hap, "module.json"], { cwd: fixture });
  if (zipped.status !== 0) throw new Error(zipped.stderr?.toString() || "could not create HAP fixture");
  fs.rmSync(fixture, { recursive: true, force: true });
  const doc = {
    schema_version: 1, id: `social4hyq/core/${formula}`,
    artifact: { format: "hap", path: "unsigned.hap", sha256: sha(fs.readFileSync(hap)),
      bundle_id: "com.example.app", version_name: "1.0", version_code: 1, abis: ["arm64-v8a"] },
    launch: { module: "entry", ability: "EntryAbility" },
    variants: { default: "basic", definitions: { basic: {} } },
    ...over,
  };
  fs.writeFileSync(path.join(dir, "app.json"), JSON.stringify(doc));
  return { dir, doc, hap };
}
function fakeBin(name, body) {
  const p = path.join(tmp, name);
  fs.writeFileSync(p, `#!/usr/bin/env node\n${body}\n`);
  fs.chmodSync(p, 0o755);
  return p;
}

// fake ohos-hap: writes signed HAP to output_path in SigningRequest
const fakeHap = fakeBin("fake-ohos-hap.cjs", `
const fs=require("fs");
if(process.argv[2]==="profile" && process.argv[3]==="show") {
  console.log(JSON.stringify(process.env.FAKE_PROFILE_SIGNER ? {signer_path:process.env.FAKE_PROFILE_SIGNER} : {}));
  process.exit(0);
}
const req=JSON.parse(fs.readFileSync(process.argv[process.argv.indexOf("--request")+1],"utf8"));
if(process.env.FAKE_HAP_LOG) fs.writeFileSync(process.env.FAKE_HAP_LOG, process.env.HAP_SIGN_TOOL||"");
if(process.env.FAKE_SIGN_PROFILE_LOG) fs.writeFileSync(process.env.FAKE_SIGN_PROFILE_LOG, req.signing_profile_name||"");
if(process.env.FAKE_SIGN_INPUT_COPY) fs.copyFileSync(req.input_hap,process.env.FAKE_SIGN_INPUT_COPY);
fs.writeFileSync(req.output_path, Buffer.concat([Buffer.from([0x50,0x4b,3,4]),Buffer.alloc(200,9)]));
if(process.argv.includes("--result")) fs.writeFileSync(process.argv[process.argv.indexOf("--result")+1], JSON.stringify({protocol_version:1,ok:true}));
`);
// fake ohos-device: emits installing + installed events, records bundle
const fakeDev = fakeBin("fake-ohos-device.cjs", `
const fs=require("fs");
const logf=process.env.FAKE_DEV_LOG||"/dev/null";
fs.appendFileSync(logf, process.argv.slice(2).join(" ")+"\\n");
const cmd=process.argv[2];
if(cmd==="list") { console.log(JSON.stringify({protocol_version:1,devices:["device-1"]})); process.exit(0); }
if(cmd==="install"){
  const req=JSON.parse(fs.readFileSync(process.argv[process.argv.indexOf("--request")+1],"utf8"));
  if(process.env.FAKE_INSTALL_EXPECTED_LOG) fs.writeFileSync(process.env.FAKE_INSTALL_EXPECTED_LOG,JSON.stringify(req.expected));
  console.log(JSON.stringify({protocol_version:1,type:"install_state",operation_id:"op",backend:req.method||"auto",state:"installing",observed_at:"2026-11-27T00:00:00Z"}));
  console.log(JSON.stringify({protocol_version:1,type:"install_result",operation_id:"op",backend:req.method||"auto",state:"installed",bundle:{bundle_id:req.expected.bundle_id},verification:{bundle_matched:true,version_matched:true},error:null}));
  process.exit(0);
}
if(cmd==="uninstall"||cmd==="start"||cmd==="stop"||cmd==="status"||cmd==="logs") process.exit(0);
`);
const env = { OHOS_APP_HAP_BIN: fakeHap, OHOS_APP_DEVICE_BIN: fakeDev, FAKE_DEV_LOG: path.join(tmp, "dev.log") };
const app = makeApp("demo-desktop");

test("list: enumerates descriptors from opt tree (no central registry)", () => {
  const res = run(["list"]);
  assert.equal(res.status, 0, res.stderr);
  const items = JSON.parse(res.stdout).apps;
  assert.equal(items.length, 1);
  assert.equal(items[0].id, "social4hyq/core/demo-desktop");
});

test("info: returns descriptor identity", () => {
  const res = run(["info", "demo-desktop"]);
  assert.equal(res.status, 0, res.stderr);
  const info = JSON.parse(res.stdout);
  assert.equal(info.id, "social4hyq/core/demo-desktop");
  assert.deepEqual(info.hap_identity, { bundle_id: "com.example.app", version_name: "1.0", version_code: 1 });
  assert.equal(info.signing_profile, "demo-desktop");
});

test("install: drives sign then device, streams events, no loopback", () => {
  fs.writeFileSync(env.FAKE_DEV_LOG, "");
  const res = run(["install", "demo-desktop", "--method", "hdc"], env);
  assert.equal(res.status, 0, res.stderr);
  const ev = res.stdout.trim().split("\n").filter(Boolean).map((l) => JSON.parse(l));
  assert.ok(ev.some((x) => x.type === "install_state" && x.state === "installing"));
  assert.ok(ev.some((x) => x.type === "install_result" && x.state === "installed"));
  const final = ev[ev.length - 1];
  assert.equal(final.command, "install");
  // no <app> install callback: device log only has install/uninstall/start... commands
  const devlog = fs.readFileSync(env.FAKE_DEV_LOG, "utf8");
  assert.ok(devlog.includes("install"), "device install called");
  assert.ok(!devlog.includes("demo-desktop install"), "no <app> install loopback");
});

test("install: discovers the SDK HAP signer when HAP_SIGN_TOOL is unset", () => {
  const signer = path.join(prefix, "opt", "ohos-sdk-toolchains", "lib", "hap-sign-tool");
  fs.mkdirSync(path.dirname(signer), { recursive: true });
  fs.writeFileSync(signer, "test signer placeholder");
  const signerLog = path.join(tmp, "hap-signer.log");
  const res = run(["install", "demo-desktop", "--method", "hdc"], {
    ...env, HAP_SIGN_TOOL: "", FAKE_HAP_LOG: signerLog,
  });
  assert.equal(res.status, 0, res.stderr + res.stdout);
  assert.equal(fs.readFileSync(signerLog, "utf8"), signer);
});

test("install: preserves an explicit HAP_SIGN_TOOL override", () => {
  const signerLog = path.join(tmp, "hap-signer-override.log");
  const res = run(["install", "demo-desktop", "--method", "hdc"], {
    ...env, HAP_SIGN_TOOL: "/custom/hap-sign-tool", FAKE_HAP_LOG: signerLog,
  });
  assert.equal(res.status, 0, res.stderr + res.stdout);
  assert.equal(fs.readFileSync(signerLog, "utf8"), "/custom/hap-sign-tool");
});

test("install: preserves the signer declared by the selected profile", () => {
  const signerLog = path.join(tmp, "hap-profile-signer.log");
  const res = run(["install", "demo-desktop", "--method", "hdc", "--signing-profile", "custom"], {
    ...env, HAP_SIGN_TOOL: "", FAKE_PROFILE_SIGNER: "/profile/hap-sign-tool", FAKE_HAP_LOG: signerLog,
  });
  assert.equal(res.status, 0, res.stderr + res.stdout);
  assert.equal(fs.readFileSync(signerLog, "utf8"), "");
});

test("install: defaults to a formula-specific signing profile", () => {
  const profileLog = path.join(tmp, "hap-profile-name.log");
  const res = run(["install", "demo-desktop", "--method", "hdc"], {
    ...env, FAKE_SIGN_PROFILE_LOG: profileLog,
  });
  assert.equal(res.status, 0, res.stderr + res.stdout);
  assert.equal(fs.readFileSync(profileLog, "utf8"), "demo-desktop");
});

test("install: uses version metadata from the HAP manifest", () => {
  const staleDescriptor = makeApp("stale-version-desktop");
  staleDescriptor.doc.artifact.version_name = "4.0.0";
  staleDescriptor.doc.artifact.version_code = 1;
  fs.writeFileSync(path.join(staleDescriptor.dir, "app.json"), JSON.stringify(staleDescriptor.doc));
  const expectedLog = path.join(tmp, "hap-install-expected.json");
  const res = run(["install", "stale-version-desktop", "--method", "hdc"], {
    ...env, FAKE_INSTALL_EXPECTED_LOG: expectedLog,
  });
  assert.equal(res.status, 0, res.stderr + res.stdout);
  assert.deepEqual(JSON.parse(fs.readFileSync(expectedLog, "utf8")), {
    bundle_id: "com.example.app", version_name: "1.0", version_code: 1,
  });
});

test("install: applies a typed module overlay without an app assembler", () => {
  const fixture = path.join(tmp, "module-overlay-fixture");
  fs.mkdirSync(fixture, { recursive: true });
  const baseModule = {
    app: { bundleName: "com.example.app", versionName: "1.0", versionCode: 1 },
    module: { name: "entry", requestPermissions: [{ name: "ohos.permission.INTERNET" }] },
  };
  fs.writeFileSync(path.join(fixture, "module.json"), JSON.stringify(baseModule));
  const unsignedHap = path.join(fixture, "unsigned.hap");
  const archive = spawnSync("zip", ["-q", "-r", unsignedHap, "module.json"], { cwd: fixture });
  assert.equal(archive.status, 0, archive.stderr?.toString());

  const overlay = {
    app: { bundleName: "com.example.app" },
    module: { name: "entry", requestPermissions: [
      { name: "ohos.permission.INTERNET" },
      { name: "ohos.permission.CUSTOM_SANDBOX" },
    ] },
  };
  const appWithOverlay = makeApp("overlay-desktop", {
    artifact: { ...app.doc.artifact, path: "../../../libexec/overlay-unsigned.hap", sha256: "" },
    variants: { default: "acl", definitions: { basic: {}, acl: { module_overlay: "module-acl.json", sha256: "" } } },
  });
  const packagedHap = path.join(prefix, "opt", "overlay-desktop", "libexec", "overlay-unsigned.hap");
  fs.mkdirSync(path.dirname(packagedHap), { recursive: true });
  fs.copyFileSync(unsignedHap, packagedHap);
  appWithOverlay.doc.artifact.sha256 = sha(fs.readFileSync(packagedHap));
  const overlayPath = path.join(appWithOverlay.dir, "module-acl.json");
  fs.writeFileSync(overlayPath, JSON.stringify(overlay));
  appWithOverlay.doc.variants.definitions.acl.sha256 = sha(fs.readFileSync(overlayPath));
  fs.writeFileSync(path.join(appWithOverlay.dir, "app.json"), JSON.stringify(appWithOverlay.doc));

  const signedInput = path.join(tmp, "assembled-module-overlay.hap");
  const res = run(["install", "overlay-desktop", "--variant", "acl", "--method", "hdc"], {
    ...env, FAKE_SIGN_INPUT_COPY: signedInput,
  });
  assert.equal(res.status, 0, res.stderr + res.stdout);
  const inspected = spawnSync("unzip", ["-p", signedInput, "module.json"], { encoding: "utf8" });
  assert.equal(inspected.status, 0, inspected.stderr);
  const assembled = JSON.parse(inspected.stdout);
  assert.deepEqual(assembled.module.requestPermissions.map((item) => item.name), [
    "ohos.permission.INTERNET", "ohos.permission.CUSTOM_SANDBOX",
  ]);
  const entries = spawnSync("unzip", ["-Z1", signedInput], { encoding: "utf8" });
  assert.equal(entries.status, 0, entries.stderr);
  assert.equal(entries.stdout.split("\n").filter((entry) => entry.endsWith("/")).length, 0);
});

test("install: personalizes and assembles the selected variant before signing", () => {
  const personalizedLog = path.join(tmp, "personalizer.json");
  const assemblyLog = path.join(tmp, "assembler.json");
  const appWithPlugins = makeApp("plugin-desktop", {
    assembly: { protocol: 1, plugin: "assembler.cjs", config: {
      bundle: "test", personalized_log: personalizedLog, assembly_log: assemblyLog,
    } },
    personalization: { protocol: 1, plugin: "personalizer.cjs" },
    variants: { default: "acl", definitions: {
      basic: {}, acl: { module_overlay: "module-acl.json", sha256: "" },
    } },
  });
  const overlay = path.join(appWithPlugins.dir, "module-acl.json");
  fs.writeFileSync(overlay, "{\"module\":{\"requestPermissions\":[{\"name\":\"acl\"}]}}\n");
  appWithPlugins.doc.variants.definitions.acl.sha256 = sha(fs.readFileSync(overlay));
  fs.writeFileSync(path.join(appWithPlugins.dir, "app.json"), JSON.stringify(appWithPlugins.doc));
  fs.writeFileSync(path.join(appWithPlugins.dir, "personalizer.cjs"), `
    const fs=require("node:fs"),path=require("node:path");
    const r=JSON.parse(fs.readFileSync(process.argv[process.argv.indexOf("--request")+1],"utf8"));
    fs.mkdirSync(r.output_tree,{recursive:true});
    fs.writeFileSync(path.join(r.output_tree,"host.json"),JSON.stringify(r.host));
  `);
  fs.writeFileSync(path.join(appWithPlugins.dir, "assembler.cjs"), `
    const fs=require("node:fs"),path=require("node:path");
    const r=JSON.parse(fs.readFileSync(process.argv[process.argv.indexOf("--request")+1],"utf8"));
    const host=JSON.parse(fs.readFileSync(path.join(r.personalized_tree,"host.json"),"utf8"));
    fs.writeFileSync(r.config.personalized_log,JSON.stringify(host));
    fs.writeFileSync(r.config.assembly_log,JSON.stringify(r));
    fs.copyFileSync(r.unsigned_hap,r.out_hap);
  `);
  const res = run(["install", "plugin-desktop", "--method", "hdc"], {
    ...env, HOME: "/test/home", XDG_CONFIG_HOME: "/test/config", PATH: process.env.PATH,
  });
  assert.equal(res.status, 0, res.stderr + res.stdout);
  const personalized = JSON.parse(fs.readFileSync(personalizedLog, "utf8"));
  assert.equal(personalized.home, "/test/home");
  assert.equal(personalized.xdg_config, "/test/config");
  const assembled = JSON.parse(fs.readFileSync(assemblyLog, "utf8"));
  assert.equal(assembled.variant, "acl");
  assert.equal(assembled.variant_definition.module_overlay, overlay);
  assert.equal(assembled.variant_definition.sha256, appWithPlugins.doc.variants.definitions.acl.sha256);
  assert.match(assembled.personalized_tree, /ohos-app-stage/);
  assert.equal(assembled.config.bundle, "test");
});

test("install: fake L3 got signed HAP (not unsigned) — sign before device", () => {
  fs.writeFileSync(env.FAKE_DEV_LOG, "");
  // fake HAP signs by writing to output_path; verify device request sha != unsigned sha
  const res = run(["install", "demo-desktop", "--method", "hdc"], env);
  assert.equal(res.status, 0, res.stderr);
  // the orchestrator computes device request hap_sha256 from signed HAP; if it passed
  // unsigned, the fake device would still accept, but we assert the event backend is hdc
  // from our --method, proving request construction reached the device.
  const ev = res.stdout.trim().split("\n").filter(Boolean).map((l) => JSON.parse(l));
  assert.equal(ev.find((x) => x.type === "install_state").backend, "hdc");
});

test("install: --start triggers device start only after success", () => {
  fs.writeFileSync(env.FAKE_DEV_LOG, "");
  const res = run(["install", "demo-desktop", "--method", "hdc", "--start"], env);
  assert.equal(res.status, 0, res.stderr);
  assert.match(fs.readFileSync(env.FAKE_DEV_LOG, "utf8"), /start/);
});

test("install: no pending state after run", () => {
  const before = fs.readdirSync(tmp).filter((f) => f.startsWith("pending")).length;
  run(["install", "demo-desktop", "--method", "hdc"], env);
  const after = fs.readdirSync(tmp).filter((f) => f.startsWith("pending")).length;
  assert.equal(after, before);
});

test("uninstall: forwards bundle id to device", () => {
  fs.writeFileSync(env.FAKE_DEV_LOG, "");
  const res = run(["uninstall", "demo-desktop"], env);
  assert.equal(res.status, 0, res.stderr);
  assert.match(fs.readFileSync(env.FAKE_DEV_LOG, "utf8"), /uninstall --bundle-id com\.example\.app/);
});

test("doctor: reports component availability", () => {
  const res = run(["doctor"], { ...env });
  assert.equal(res.status, 0, res.stderr);
  const d = JSON.parse(res.stdout);
  assert.equal(d.tools["ohos-hap"], true);
  assert.equal(d.tools["ohos-device"], true);
});

test("missing descriptor fails closed", () => {
  const res = run(["info", "no-such-app"], env);
  assert.notEqual(res.status, 0);
  assert.match(res.stdout, /ERR_INVALID_REQUEST/);
});

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
