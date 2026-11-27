#!/usr/bin/env node
"use strict";
// Contract tests for ohos-hap using a fake signer. No real DevEco CLI, no device.
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");
const { spawnSync } = require("node:child_process");

const CLI = path.join(__dirname, "ohos-hap.cjs");
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "ohos-hap-test-"));
let passed = 0, failed = 0;
function test(name, fn) {
  try { fn(); passed += 1; console.log("PASS", name); }
  catch (e) { failed += 1; console.error("FAIL", name, "-", e.message); }
}
function run(args, env = {}) {
  return spawnSync(process.execPath, [CLI, ...args], {
    encoding: "utf8", env: { ...process.env, ...env },
  });
}
function mkfile(name, content = "x") {
  const p = path.join(tmp, name); fs.writeFileSync(p, content); return p;
}
function writeProfiles(doc) {
  const dir = path.join(tmp, "config/ohos-hap"); fs.mkdirSync(dir, { recursive: true });
  const f = path.join(dir, "profiles.json"); fs.writeFileSync(f, JSON.stringify(doc)); return f;
}
function makeHap() {
  // minimal zip-shaped buffer (PK header) big enough for verifyStructure
  const p = path.join(tmp, "app.hap");
  fs.writeFileSync(p, Buffer.concat([Buffer.from([0x50, 0x4b, 3, 4]), Buffer.alloc(200, 1)]));
  return p;
}
function fakeSigner() {
  // writes a signed HAP to the --outFile argument and echoes a secret-looking token
  const p = path.join(tmp, "fake-signer.sh");
  fs.writeFileSync(p, `#!/bin/sh
out=""
prev=""
for a in "$@"; do
  if [ "$prev" = "-outFile" ]; then out="$a"; fi
  prev="$a"
done
printf 'PK\\003\\004' > "$out"
head -c 200 /dev/zero >> "$out"
printf 'signer-output secret-should-be-redacted\\n' >&2
exit 0
`);
  fs.chmodSync(p, 0o755);
  return p;
}
function baseRequest(overrides = {}) {
  return {
    protocol_version: 1, input_hap: makeHap(),
    output_path: path.join(tmp, "signed.hap"),
    signing_profile_name: "ext",
    expected: { bundle_id: "com.example.app", version_code: 1 },
    ...overrides,
  };
}

// ---- setup: external profile with env-ref passwords ----
const store = mkfile("store.p12"); const cert = mkfile("cert.cer"); const prof = mkfile("prof.p7b");
writeProfiles({ profiles: { ext: {
  kind: "external-material", keystore_path: store, certificate_path: cert, p7b_path: prof,
  key_alias: "k", sign_alg: "SHA256withECDSA",
  store_password_ref: "env:TEST_STORE_PWD", key_password_ref: "env:TEST_KEY_PWD",
} } });
process.env.XDG_CONFIG_HOME = path.join(tmp, "config");
process.env.TEST_STORE_PWD = "s3cr3t-store";
process.env.TEST_KEY_PWD = "s3cr3t-key";
const signer = fakeSigner();

test("sign: external-material path produces contract result", () => {
  const req = baseRequest();
  const rf = path.join(tmp, "req.json"); fs.writeFileSync(rf, JSON.stringify(req));
  const res = run(["sign", "--request", rf, "--signer", signer]);
  assert.equal(res.status, 0, res.stderr);
  const doc = JSON.parse(res.stdout.trim().split("\n").pop());
  assert.equal(doc.ok, true);
  assert.equal(doc.protocol_version, 1);
  assert.equal(doc.verification.structure_ok, true);
});

test("sign: secrets redacted from signer output", () => {
  const req = baseRequest({ output_path: path.join(tmp, "signed2.hap") });
  const rf = path.join(tmp, "req2.json"); fs.writeFileSync(rf, JSON.stringify(req));
  const res = run(["sign", "--request", rf, "--signer", signer]);
  assert.equal(res.status, 0, res.stderr);
  assert.ok(!res.stdout.includes("s3cr3t-store") && !res.stderr.includes("s3cr3t-store"), "store pwd leaked");
  assert.ok(!res.stdout.includes("s3cr3t-key") && !res.stderr.includes("s3cr3t-key"), "key pwd leaked");
});

test("sign: wrong protocol_version fails closed", () => {
  const req = baseRequest({ protocol_version: 99 });
  const rf = path.join(tmp, "req3.json"); fs.writeFileSync(rf, JSON.stringify(req));
  const res = run(["sign", "--request", rf, "--signer", signer]);
  assert.notEqual(res.status, 0);
  assert.match(res.stderr, /ERR_UNSUPPORTED_PROTOCOL/);
});

test("sign: unknown profile fails with ERR_INVALID_REQUEST", () => {
  const req = baseRequest({ signing_profile_name: "missing" });
  const rf = path.join(tmp, "req4.json"); fs.writeFileSync(rf, JSON.stringify(req));
  const res = run(["sign", "--request", rf, "--signer", signer]);
  assert.notEqual(res.status, 0);
  assert.match(res.stderr, /ERR_INVALID_REQUEST/);
});

test("sign: no signer configured fails with ERR_BACKEND_UNAVAILABLE", () => {
  const req = baseRequest({ output_path: path.join(tmp, "signed5.hap") });
  const rf = path.join(tmp, "req5.json"); fs.writeFileSync(rf, JSON.stringify(req));
  const env = { ...process.env }; delete env.HAP_SIGN_TOOL;
  const res = run(["sign", "--request", rf], env);
  assert.notEqual(res.status, 0);
  assert.match(res.stderr, /ERR_BACKEND_UNAVAILABLE/);
});

test("verify: non-zip file fails", () => {
  const bad = mkfile("bad.hap", "not a zip at all but long enough to be a file for the check");
  const res = run(["verify", "--hap", bad]);
  assert.notEqual(res.status, 0);
  assert.match(res.stderr, /ERR_SIGN_VERIFY_FAILED/);
});

test("doctor: reports argv residual risk note", () => {
  const res = run(["doctor"]);
  assert.equal(res.status, 0);
  assert.match(res.stdout, /residual risk/);
});

test("inspect: emits signed-hap source contract", () => {
  // 内嵌最小 zip（含 module.json），不依赖外部 zip 命令——CI 的 formula test
  // 环境 PATH 只含该 formula 的依赖（ohos-hap 只依赖 node），没有 zip。
  const b64 = "UEsDBBQAAAAIAFtRe11qvtbIegAAALYAAAALAAAAbW9kdWxlLmpzb26rVsrNTynNSVWyqlYqSi0sTS0uCUgtys0sLs7MzytWsoquVspLzAVKK+Vn5BfrFcDl9Dz9QlyD/FxDlGp1cKpxDg0O8feND3b0c3Hyj8CnMsjV0SU+wDE4xNXJ3zHIRUlHKb0oMa/ENz8FpLq0OLUoHiygVBtbW8sFAFBLAQIeAxQAAAAIAFtRe11qvtbIegAAALYAAAALAAAAAAAAAAEAAAC0gQAAAABtb2R1bGUuanNvblBLBQYAAAAAAQABADkAAACjAAAAAAA=";
  const hap = path.join(tmp, "inspect.hap");
  fs.writeFileSync(hap, Buffer.from(b64, "base64"));
  const res = run(["inspect", "--hap", hap]);
  assert.equal(res.status, 0, res.stderr);
  const doc = JSON.parse(res.stdout.trim().split("\n").pop());
  assert.equal(doc.source, "signed-hap");
  assert.equal(doc.requested_permissions.length, 3);
  const acl = doc.requested_permissions.find((p) => p.name.includes("CUSTOM_SANDBOX"));
  assert.equal(acl.acl, true);
  const paste = doc.requested_permissions.find((p) => p.name.includes("PASTEBOARD"));
  assert.equal(paste.grant_mode, "user_grant");
});

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
