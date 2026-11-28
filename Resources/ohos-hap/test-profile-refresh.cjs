#!/usr/bin/env node
"use strict";
// Integration tests for `ohos-hap profile refresh` using a mock vendor CLI.
// No real DevEco account or signing service: the mock CLI creates a project,
// writes a build-profile with encrypted-looking password placeholders, and
// exposes a decoder that reverses them.
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");
const { spawnSync } = require("node:child_process");

const CLI = path.join(__dirname, "ohos-hap.cjs");
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "ohos-hap-refresh-"));
let passed = 0, failed = 0;
function test(name, fn) {
  try { fn(); passed += 1; console.log("PASS", name); }
  catch (e) { failed += 1; console.error("FAIL", name, "-", e.message); }
}
function sh(cmd) { const r = spawnSync("bash", ["-c", cmd], { encoding: "utf8" }); if (r.status !== 0) throw new Error(`${cmd}: ${r.stderr}`); }

// Build a mock vendor CLI: a node script with auth/create/signature commands,
// a json5 module resolvable from its directory, and a decoder class whose
// decryptPwd reverses a reversible placeholder.
function makeVendorCli() {
  const root = path.join(tmp, "vendor");
  const bin = path.join(root, "bin");
  fs.mkdirSync(path.join(bin, "node_modules", "json5"), { recursive: true });
  fs.writeFileSync(path.join(root, "package.json"), JSON.stringify({ version: "mock-1" }));
  fs.writeFileSync(path.join(bin, "node_modules", "json5", "index.js"),
    'module.exports = { parse(s) { return JSON.parse(s.replace(/,(\\s*[}\\]])/g, "$1")); } };');
  fs.writeFileSync(path.join(bin, "node_modules", "json5", "package.json"),
    JSON.stringify({ name: "json5", version: "1", main: "index.js" }));
  // Build the mock CLI source with an array of lines to avoid nested template
  // literals (the decoder alias scanner requires a backtick logger call).
  const lines = [
    '#!/usr/bin/env node',
    'const fs = require("node:fs"), path = require("node:path");',
    'const cmd = process.argv[2];',
    'if (cmd === "auth") { console.log("Logged in as dev@example.com"); process.exit(0); }',
    'if (cmd === "create") {',
    '  const p = process.argv[process.argv.indexOf("--project-path") + 1];',
    '  fs.mkdirSync(path.join(p, "AppScope"), { recursive: true });',
    '  fs.mkdirSync(path.join(p, "entry/src/main"), { recursive: true });',
    '  fs.writeFileSync(path.join(p, "AppScope/app.json5"), "{}");',
    '  fs.writeFileSync(path.join(p, "entry/src/main/module.json5"), JSON.stringify({ module: {} }));',
    '  process.exit(0);',
    '}',
    'if (cmd === "signature") {',
    '  const p = process.cwd();',
    '  fs.writeFileSync(path.join(p, "build-profile.json5"), JSON.stringify({',
    '    app: { signingConfigs: [{ name: "default", material: {',
    '      storeFile: "key.p12", certpath: "cert.cer", profile: "prof.p7b", keyAlias: "k0",',
    '      storePassword: "ENC-storePASS", keyPassword: "ENC-keyPASS", signAlg: "SHA256withECDSA",',
    '    }}] },',
    '  }));',
    '  process.exit(0);',
    '}',
    'process.exit(1);',
    'const DecipherUtil = class {',
    '  static decryptPwd(configDir, enc, label) {',
    '    const p = path.resolve(configDir, label);',
    '    const c = crypto.createDecipheriv("aes-256-cbc", Buffer.alloc(32), Buffer.alloc(16));',
    '    const names = fs.readdirSync(configDir);',
    '    logger(`[DecipherUtil] ${label} ${names.length}`);',
    '    void p; void c;',
    '    return String(enc).replace(/^ENC-/, "");',
    '  }',
    '};',
  ];
  const cli = path.join(bin, "devecocli");
  fs.writeFileSync(cli, lines.join("\n"));
  fs.chmodSync(cli, 0o755);
  return cli;
}

function makeHap(bundleId) {
  // Build a minimal zip with module.json carrying the bundle name and one
  // requested permission, which prepare-profile.cjs reads and syncs.
  const p = path.join(tmp, "app.hap");
  const mod = { app: { bundleName: bundleId }, module: { requestPermissions: [{ name: "ohos.permission.INTERNET" }] } };
  const b64 = spawnSync("python3", ["-c", `
import zipfile,sys
z=zipfile.ZipFile(sys.argv[1],"w")
z.writestr("module.json", sys.argv[2])
z.writestr("sig", b"x"*100)
z.close()
`, p, JSON.stringify(mod)], { encoding: "utf8" });
  if (b64.status !== 0) throw new Error("makeHap: " + b64.stderr);
  return p;
}

const vendor = makeVendorCli();
const hap = makeHap("com.social4hyq.demo");
const cfg = path.join(tmp, "config");
const project = path.join(tmp, "project");

test("refresh: generates vendor-debug profile with secret file ref", () => {
  const r = spawnSync(process.execPath, [CLI, "profile", "refresh", "mydebug",
    "--hap", hap, "--bundle-id", "com.social4hyq.demo", "--project", project],
    { encoding: "utf8", env: { ...process.env, XDG_CONFIG_HOME: cfg,
      OHOS_HAP_VENDOR_CLI: vendor, DEVECO_CLI_JS: vendor } });
  if (r.status !== 0) console.error("REFRESH STDERR:", r.stderr, "STDOUT:", r.stdout);
  assert.equal(r.status, 0, r.stderr);
  const profiles = JSON.parse(fs.readFileSync(path.join(cfg, "ohos-hap/profiles.json"), "utf8"));
  const p = profiles.profiles.mydebug;
  assert.equal(p.kind, "vendor-debug");
  assert.match(p.store_password_ref, /^file:/);
  const storeSecret = p.store_password_ref.slice(5);
  const keySecret = p.key_password_ref.slice(5);
  assert.notEqual(storeSecret, keySecret); // separate files: resolveEnvRef reads the whole file as one value
  for (const f of [storeSecret, keySecret]) {
    assert.equal(fs.statSync(f).mode & 0o777, 0o600);
    assert.equal(fs.readFileSync(f, "utf8").trim().split("\n").length, 1); // one password per file
  }
  assert.match(fs.readFileSync(storeSecret, "utf8"), /storePASS/); // decoded, not ENC-
  assert.equal(JSON.stringify(profiles).includes("ENC-storePASS"), false);
});

test("refresh: missing --hap fails closed", () => {
  const r = spawnSync(process.execPath, [CLI, "profile", "refresh", "x",
    "--bundle-id", "com.x", "--project", project],
    { encoding: "utf8", env: { ...process.env, XDG_CONFIG_HOME: cfg, OHOS_HAP_VENDOR_CLI: vendor } });
  assert.notEqual(r.status, 0);
  assert.match(r.stderr, /--hap/);
});

test("refresh: no vendor CLI fails closed", () => {
  const r = spawnSync(process.execPath, [CLI, "profile", "refresh", "x",
    "--hap", hap, "--bundle-id", "com.x", "--project", project],
    { encoding: "utf8", env: { ...process.env, XDG_CONFIG_HOME: cfg,
      OHOS_HAP_VENDOR_CLI: path.join(tmp, "no-cli"), DEVECO_CLI_JS: "" } });
  assert.notEqual(r.status, 0);
  assert.match(r.stderr, /ERR_VENDOR_AUTH_REQUIRED/);
});

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
