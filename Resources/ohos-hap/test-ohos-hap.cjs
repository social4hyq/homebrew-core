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
  // A minimal inline zip containing module.json, so no external zip is needed.
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

test("profile: add writes external-material profile with secret refs only", () => {
  const cfg = path.join(tmp, "addcfg"); fs.mkdirSync(cfg, { recursive: true });
  const store = mkfile("my.p12"), cert = mkfile("my.cer"), p7b = mkfile("my.p7b");
  const res = run(["profile", "add", "ext2", "--keystore", store, "--cert", cert,
    "--p7b", p7b, "--alias", "key0", "--store-password-ref", "env:STORE_PWD"],
    { XDG_CONFIG_HOME: cfg });
  assert.equal(res.status, 0, res.stderr);
  const doc = JSON.parse(fs.readFileSync(path.join(cfg, "ohos-hap/profiles.json"), "utf8"));
  assert.equal(doc.profiles.ext2.kind, "external-material");
  assert.equal(doc.profiles.ext2.store_password_ref, "env:STORE_PWD");
  assert.equal(JSON.stringify(doc).includes("STORE_PWD="), false); // no secret values, only refs
});

test("profile: add rejects inline password (not a ref)", () => {
  const cfg = path.join(tmp, "addcfg2"); fs.mkdirSync(cfg, { recursive: true });
  const store = mkfile("a.p12"), cert = mkfile("a.cer"), p7b = mkfile("a.p7b");
  const res = run(["profile", "add", "bad", "--keystore", store, "--cert", cert,
    "--p7b", p7b, "--alias", "key0", "--store-password-ref", "secret123"],
    { XDG_CONFIG_HOME: cfg });
  assert.notEqual(res.status, 0);
  assert.match(res.stderr, /env: or file:/);
});

test("profile: add rejects missing material file", () => {
  const cfg = path.join(tmp, "addcfg3"); fs.mkdirSync(cfg, { recursive: true });
  const cert = mkfile("b.cer"), p7b = mkfile("b.p7b");
  const res = run(["profile", "add", "bad2", "--keystore", path.join(tmp, "nope.p12"),
    "--cert", cert, "--p7b", p7b, "--alias", "key0", "--store-password-ref", "env:X"],
    { XDG_CONFIG_HOME: cfg });
  assert.notEqual(res.status, 0);
  assert.match(res.stderr, /file not found/);
});

test("profile: remove deletes the named profile", () => {
  const cfg = path.join(tmp, "addcfg");
  const res = run(["profile", "remove", "ext2"], { XDG_CONFIG_HOME: cfg });
  assert.equal(res.status, 0, res.stderr);
  const doc = JSON.parse(fs.readFileSync(path.join(cfg, "ohos-hap/profiles.json"), "utf8"));
  assert.equal(doc.profiles.ext2, undefined);
});

test("profile: refresh requires explicit parameters", () => {
  const res = run(["profile", "refresh"]);
  assert.notEqual(res.status, 0);
  assert.match(res.stderr, /needs/); // requires explicit name/params, never implicit
});

// Mock vendor CLI: records invocations and reports a configurable auth state.
function mockVendorCli(label, state) {
  const p = path.join(tmp, `mock-cli-${label}.sh`);
  const log = path.join(tmp, `mock-cli-${label}.log`);
  fs.writeFileSync(p, `#!/bin/sh
printf '%s\n' "$*" >> "${log}"
case "$1 $2" in
  "auth status")
    case "${state}" in
      logged-in) echo "Logged in as dev@example.com" ;;
      not-logged-in) echo "Not logged in" ;;
      unavailable) echo "cli error" >&2; exit 7 ;;
    esac ;;
  "auth login") echo "Please open https://developer.huawei.com/login?code=abc to sign in" ;;
  "auth logout") echo "logged out" ;;
esac
exit 0
`);
  fs.chmodSync(p, 0o755);
  return { cli: p, log };
}

test("auth: status reports logged-in via vendor CLI", () => {
  const m = mockVendorCli("in", "logged-in");
  const res = run(["auth", "status"], { OHOS_HAP_VENDOR_CLI: m.cli, OHOS_HAP_AUTH_NO_BROWSER: "1" });
  assert.equal(res.status, 0, res.stderr);
  const doc = JSON.parse(res.stdout.trim().split("\n").pop());
  assert.equal(doc.subcommand, "status");
  assert.equal(doc.state, "logged-in");
  assert.match(fs.readFileSync(m.log, "utf8"), /auth status/);
});

test("auth: status reports not-logged-in", () => {
  const m = mockVendorCli("out", "not-logged-in");
  const res = run(["auth", "status"], { OHOS_HAP_VENDOR_CLI: m.cli, OHOS_HAP_AUTH_NO_BROWSER: "1" });
  assert.equal(res.status, 0, res.stderr);
  const doc = JSON.parse(res.stdout.trim().split("\n").pop());
  assert.equal(doc.state, "not-logged-in");
});

test("auth: status fails closed when vendor CLI errors", () => {
  const m = mockVendorCli("err", "unavailable");
  const res = run(["auth", "status"], { OHOS_HAP_VENDOR_CLI: m.cli, OHOS_HAP_AUTH_NO_BROWSER: "1" });
  assert.notEqual(res.status, 0);
  assert.match(res.stderr, /ERR_VENDOR_AUTH_REQUIRED/);
});

test("auth: login delegates to vendor CLI with no browser", () => {
  const m = mockVendorCli("login", "logged-in");
  const res = run(["auth", "login"], { OHOS_HAP_VENDOR_CLI: m.cli, OHOS_HAP_AUTH_NO_BROWSER: "1" });
  assert.equal(res.status, 0, res.stderr);
  assert.match(fs.readFileSync(m.log, "utf8"), /auth login/);
  assert.match(res.stderr, /developer\.huawei\.com/); // URL passed through
});

test("auth: logout delegates to vendor CLI", () => {
  const m = mockVendorCli("logout", "logged-in");
  const res = run(["auth", "logout"], { OHOS_HAP_VENDOR_CLI: m.cli, OHOS_HAP_AUTH_NO_BROWSER: "1" });
  assert.equal(res.status, 0, res.stderr);
  assert.match(fs.readFileSync(m.log, "utf8"), /auth logout/);
});

test("auth: fails closed when no vendor CLI is available", () => {
  const res = run(["auth", "status"], {
    OHOS_HAP_VENDOR_CLI: path.join(tmp, "no-such-cli"), OHOS_HAP_AUTH_NO_BROWSER: "1",
  });
  assert.notEqual(res.status, 0);
  assert.match(res.stderr, /ERR_VENDOR_AUTH_REQUIRED/);
});

test("auth: rejects unsupported subcommand", () => {
  const res = run(["auth", "bogus"]);
  assert.notEqual(res.status, 0);
  assert.match(res.stderr, /ERR_INVALID_REQUEST/);
});

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
