#!/usr/bin/env node
"use strict";

// ohos-hap: sign / verify / inspect HAP packages. Consumes the L0 SigningRequest
// contract (requests/sign/request.schema.json). It NEVER touches devices, app
// descriptors, host configs, or vendor login automatically.
//
// Password policy (see docs/signing-argv-protection-findings.md):
//  - external-material path: keystore/cert/profile are user-supplied; passwords
//    come from env vars named by secret_ref. The current hap-sign-tool still
//    receives them in argv (TTY-only -pwdInputMode 1 cannot be fed by pipe);
//    this residual risk is recorded, not hidden, and never triggers a login.
//  - vendor-debug path: ONLY via explicit `profile refresh`; decoder layout is
//    fail-closed. No implicit login/refresh from sign.

const fs = require("node:fs");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const devecoDecoder = require(path.join(__dirname, "lib", "deveco-decoder.cjs"));

function fail(code, message) {
  process.stderr.write(`ohos-hap: ${code}: ${message}\n`);
  process.exit(1);
}
function out(obj) { process.stdout.write(JSON.stringify(obj) + "\n"); }
function usage() {
  process.stdout.write(`Usage:
  ohos-hap sign --request FILE [--result FILE] [--signer PATH]
  ohos-hap inspect --hap FILE [--json]
  ohos-hap verify --hap FILE
  ohos-hap doctor
  ohos-hap profile list|show|add|remove|refresh
  ohos-hap auth login|logout|status
\n`);
}

function parseArgs(args) {
  const o = { _: [] };
  for (let i = 0; i < args.length; i += 1) {
    const k = args[i];
    if (k === "--help" || k === "-h") { o.help = true; continue; }
    if (k.startsWith("--")) {
      const v = args[++i];
      if (!v) fail("ERR_INVALID_REQUEST", `missing value for ${k}`);
      o[k.slice(2)] = v;
    } else o._.push(k);
  }
  return o;
}

// Resolve a SigningProfile by logical name from XDG_CONFIG_HOME/ohos-hap/profiles.json.
// Non-secret config only; secrets are referenced by env/keychain ref, never inlined.
function loadProfile(name) {
  const root = process.env.XDG_CONFIG_HOME || path.join(process.env.HOME || "", ".config");
  const file = path.join(root, "ohos-hap", "profiles.json");
  if (!fs.existsSync(file)) fail("ERR_INVALID_REQUEST", `no signing profiles at ${file}`);
  let doc;
  try { doc = JSON.parse(fs.readFileSync(file, "utf8")); }
  catch (e) { fail("ERR_INVALID_REQUEST", `cannot parse profiles.json: ${e.message}`); }
  const profile = doc.profiles?.[name];
  if (!profile) fail("ERR_INVALID_REQUEST", `unknown signing profile: ${name}`);
  return profile;
}

function resolveEnvRef(ref) {
  if (!ref || typeof ref !== "string") fail("ERR_INVALID_REQUEST", "profile has no password ref");
  if (ref.startsWith("env:")) {
    const val = process.env[ref.slice(4)];
    if (!val) fail("ERR_INVALID_REQUEST", `password env var not set: ${ref.slice(4)}`);
    return val;
  }
  if (ref.startsWith("file:")) {
    const f = ref.slice(5);
    if (!fs.existsSync(f)) fail("ERR_INVALID_REQUEST", `secret file not found: ${f}`);
    return fs.readFileSync(f, "utf8").replace(/[\r\n]+$/, "");
  }
  fail("ERR_INVALID_REQUEST", `unsupported secret ref scheme: ${ref.split(":")[0]}`);
}

function checkFiles(obj, keys) {
  for (const k of keys) {
    const p = obj[k];
    if (!p || !fs.existsSync(p) || !fs.statSync(p).isFile()) fail("ERR_INVALID_REQUEST", `file not found: ${p}`);
  }
}

function cmdSign(o) {
  if (!o.request) fail("ERR_INVALID_REQUEST", "--request is required");
  let req;
  try { req = JSON.parse(fs.readFileSync(o.request, "utf8")); }
  catch (e) { fail("ERR_INVALID_REQUEST", `cannot parse request: ${e.message}`); }
  if (req.protocol_version !== 1) fail("ERR_UNSUPPORTED_PROTOCOL", `protocol_version ${req.protocol_version}`);
  checkFiles(req, ["input_hap"]);

  const profile = loadProfile(req.signing_profile_name);
  const expected = req.expected || {};
  if (expected.bundle_id && profile.bundle_id && expected.bundle_id !== profile.bundle_id) {
    fail("ERR_INVALID_REQUEST", "request bundle_id does not match signing profile");
  }

  let material;
  if (profile.kind === "external-material") {
    material = {
      storeFile: path.resolve(profile.keystore_path),
      certpath: path.resolve(profile.certificate_path),
      profile: path.resolve(profile.p7b_path),
      keyAlias: profile.key_alias,
      signAlg: profile.sign_alg || "SHA256withECDSA",
    };
    checkFiles(material, ["storeFile", "certpath", "profile"]);
  } else if (profile.kind === "vendor-debug") {
    // Explicit-only: sign never logs in or refreshes. Material must already exist.
    material = resolveVendorMaterial(profile);
  } else {
    fail("ERR_INVALID_REQUEST", `unsupported SigningProfile.kind: ${profile.kind}`);
  }

  const storePassword = resolveEnvRef(profile.store_password_ref);
  const keyPassword = profile.key_password_ref ? resolveEnvRef(profile.key_password_ref) : storePassword;

  const signer = o.signer || process.env.HAP_SIGN_TOOL || profile.signer_path;
  if (!signer) fail("ERR_BACKEND_UNAVAILABLE", "no hap-sign-tool configured (--signer / HAP_SIGN_TOOL / profile.signer_path)");
  const argv = [signer, "sign-app", "-mode", "localSign", "-compatibleVersion", "26", "-signCode", "1",
    "-keyAlias", material.keyAlias, "-keyPwd", keyPassword, "-keystorePwd", storePassword,
    "-appCertFile", material.certpath, "-profileFile", material.profile,
    "-keystoreFile", material.storeFile, "-signAlg", material.signAlg,
    "-inFile", path.resolve(req.input_hap), "-outFile", path.resolve(req.output_path)];
  // RESIDUAL RISK (documented): passwords are in argv because the current SDK's
  // -pwdInputMode 1 is TTY-only. We redact them from captured output and never
  // echo argv; we do NOT claim the risk is eliminated.
  const result = spawnSync(argv[0], argv.slice(1), { encoding: "utf8", timeout: 120000, input: "" });
  let log = `${result.stdout || ""}${result.stderr || ""}`;
  for (const s of [storePassword, keyPassword]) if (s) log = log.split(s).join("[redacted]");
  process.stderr.write(log);
  if (result.error || result.status !== 0) fail("ERR_SIGN_FAILED", `hap-sign-tool status=${result.status}`);
  const outPath = path.resolve(req.output_path);
  if (!fs.existsSync(outPath) || fs.statSync(outPath).size === 0) fail("ERR_SIGN_FAILED", "no signed HAP produced");

  const verify = verifyStructure(outPath);
  if (!verify.ok) fail("ERR_SIGN_VERIFY_FAILED", verify.reason);
  const resultDoc = {
    protocol_version: 1, ok: true, output_hap: outPath,
    output_sha256: require("node:crypto").createHash("sha256").update(fs.readFileSync(outPath)).digest("hex"),
    certificate_fingerprint: profile.certificate_fingerprint || null,
    verification: verify, error: null,
  };
  if (o.result) fs.writeFileSync(o.result, JSON.stringify(resultDoc));
  out(resultDoc);
}

function resolveVendorMaterial(profile) {
  // Vendor debug material generated by DevEco CLI; decoder is fail-closed.
  const cfgDir = profile.vendor_state_root || path.join(process.env.HOME || "", ".ohos/config");
  const cli = process.env.DEVECO_CLI_JS || profile.vendor_cli;
  if (!cli) fail("ERR_VENDOR_AUTH_REQUIRED", "vendor-debug profile needs explicit auth first");
  const profileJson5 = profile.build_profile;
  if (!profileJson5 || !fs.existsSync(profileJson5)) fail("ERR_VENDOR_AUTH_REQUIRED", "no generated build-profile; run `ohos-hap profile refresh`");
  const profileDoc = JSON.parse(fs.readFileSync(profileJson5, "utf8"));
  const m = profileDoc.app?.signingConfigs?.[0]?.material;
  if (!m) fail("ERR_VENDOR_AUTH_REQUIRED", "build-profile has no signing material");
  const decoded = devecoDecoder.decodePasswords(cli, cfgDir, m.storePassword, m.keyPassword);
  return {
    storeFile: path.resolve(path.dirname(profileJson5), m.storeFile),
    certpath: path.resolve(path.dirname(profileJson5), m.certpath),
    profile: path.resolve(path.dirname(profileJson5), m.profile),
    keyAlias: m.keyAlias, signAlg: m.signAlg || "SHA256withECDSA",
    _passwords: decoded,
  };
}

function verifyStructure(hapPath) {
  // Structural check only: HAP is a zip with module.json + signature block.
  // Cryptographic verification is delegated to the system on install;
  // here we only assert the file is a non-trivial zip we can parse.
  try {
    const buf = fs.readFileSync(hapPath);
    if (buf.length < 100) return { ok: false, reason: "signed HAP too small" };
    if (buf[0] !== 0x50 || buf[1] !== 0x4b) return { ok: false, reason: "signed HAP is not a zip" };
    return { ok: true, structure_ok: true, signature_ok: null };
  } catch (e) { return { ok: false, reason: e.message }; }
}

function cmdInspect(o) {
  if (!o.hap) fail("ERR_INVALID_REQUEST", "--hap is required");
  if (!fs.existsSync(o.hap)) fail("ERR_INVALID_REQUEST", `file not found: ${o.hap}`);
  // Permissions are derived from the final signed HAP, not from app.json/overlay.
  // Delegated to prepare-profile's manifest reader; here we emit the contract shape.
  const { execFileSync } = require("node:child_process");
  let moduleJson;
  try {
    moduleJson = JSON.parse(execFileSync("unzip", ["-p", o.hap, "module.json"], { encoding: "utf8" }));
  } catch (e) { fail("ERR_INVALID_REQUEST", `cannot read module.json from HAP: ${e.message}`); }
  const perms = moduleJson.module?.requestPermissions || [];
  const doc = {
    source: "signed-hap",
    variant: o.variant || null,
    requested_permissions: perms.map((p) => ({
      name: p.name,
      grant_mode: /user_grant/i.test(p.grantMode || "") ? "user_grant" : "system_grant",
      acl: /CUSTOM_SANDBOX|READ_WRITE_USER_FILE|kernel\./.test(p.name),
      reason: p.reason || null, used_scene: p.usedScene || null,
    })),
  };
  out(doc);
}

function cmdVerify(o) {
  if (!o.hap) fail("ERR_INVALID_REQUEST", "--hap is required");
  const v = verifyStructure(o.hap);
  out({ protocol_version: 1, ok: v.ok, verification: v });
  if (!v.ok) { process.stderr.write(`ERR_SIGN_VERIFY_FAILED: ${v.reason}\n`); process.exit(1); }
}

function cmdDoctor() {
  const needs = { node: true, unzip: true };
  for (const tool of Object.keys(needs)) {
    const r = spawnSync("which", [tool], { encoding: "utf8" });
    needs[tool] = r.status === 0;
  }
  const signer = process.env.HAP_SIGN_TOOL || null;
  out({ protocol_version: 1, tools: needs, signer: signer || null,
    note: "argv password residual risk on current SDK; see docs/signing-argv-protection-findings.md" });
}

function cmdProfile(o) {
  const sub = o._[1];
  if (!sub) fail("ERR_INVALID_REQUEST", "profile needs a subcommand");
  if (sub === "list" || sub === "show") {
    const root = process.env.XDG_CONFIG_HOME || path.join(process.env.HOME || "", ".config");
    const f = path.join(root, "ohos-hap", "profiles.json");
    const doc = fs.existsSync(f) ? JSON.parse(fs.readFileSync(f, "utf8")) : { profiles: {} };
    if (sub === "show" && o._[2]) out(doc.profiles?.[o._[2]] || null);
    else out(doc.profiles || {});
    return;
  }
  if (sub === "refresh") {
    // Explicit vendor login/refresh only; never called from sign.
    fail("ERR_VENDOR_AUTH_REQUIRED", "profile refresh requires an interactive vendor auth flow (not implemented in this contract layer)");
  }
  fail("ERR_INVALID_REQUEST", `unsupported profile subcommand: ${sub}`);
}

function cmdAuth(o) {
  const sub = o._[1];
  out({ protocol_version: 1, subcommand: sub || "status",
    note: "vendor auth is explicit; delegated to the vendor CLI, never implicit from sign/install" });
}

function main() {
  const argv = process.argv.slice(2);
  const cmd = argv[0] || "help";
  if (cmd === "help" || cmd === "--help" || cmd === "-h") { usage(); return; }
  const o = parseArgs(argv.slice(1));
  o._ = [cmd, ...o._];
  switch (cmd) {
    case "sign": return cmdSign(o);
    case "inspect": return cmdInspect(o);
    case "verify": return cmdVerify(o);
    case "doctor": return cmdDoctor();
    case "profile": return cmdProfile(o);
    case "auth": return cmdAuth(o);
    default: fail("ERR_INVALID_REQUEST", `unknown command: ${cmd}`);
  }
}

if (require.main === module) main();
module.exports = { verifyStructure, loadProfile, resolveEnvRef };
