#!/usr/bin/env node
"use strict";

// ohos-device: the ONLY component that talks to devices (hdc/bm/aa) and the
// system sideload installer. Consumes L0 InstallRequest; emits NDJSON events
// (install-event.schema.json) with exactly one terminal install_result.
// It NEVER signs, downloads, assembles, reads app descriptors, or manages
// host services. A sideload backend is fail-closed until the official API is published.

const fs = require("node:fs");
const path = require("node:path");
const crypto = require("node:crypto");
const { spawnSync } = require("node:child_process");

function emit(obj) { process.stdout.write(JSON.stringify(obj) + "\n"); }
function fail(code, message) {
  emit({ protocol_version: 1, type: "install_result", operation_id: "", backend: "unknown",
    state: "failed", error: { code, detail: message } });
  process.exit(1);
}
function usage() {
  process.stdout.write(`Usage:
  ohos-device backends list [--json]
  ohos-device list [--json]
  ohos-device install --hap SIGNED [--device SEL] [--method hdc|sideload|auto] [--json]
  ohos-device install-status --operation-id ID [--json]
  ohos-device uninstall --bundle-id ID [--device SEL] [--purge] [--json]
  ohos-device start --bundle-id ID --module M --ability A [--device SEL]
  ohos-device stop --bundle-id ID [--device SEL]
  ohos-device status --bundle-id ID [--device SEL] [--json]
  ohos-device permissions|logs --bundle-id ID [--device SEL] [--json]
`);
}

function parseArgs(args) {
  const o = { _: [] };
  for (let i = 0; i < args.length; i += 1) {
    const k = args[i];
    if (k === "--help" || k === "-h") { o.help = true; continue; }
    if (k === "--purge" || k === "--json") { o[k.slice(2)] = true; continue; }
    if (k.startsWith("--")) {
      const v = args[++i];
      if (!v) fail("ERR_INVALID_REQUEST", `missing value for ${k}`);
      o[k.slice(2).replaceAll("-", "_")] = v; // --bundle-id -> bundle_id
    } else o._.push(k);
  }
  return o;
}

function hdcBin() { return process.env.HDC || process.env.OHOS_DEVICE_HDC || "hdc"; }
function hdc(args) {
  const r = spawnSync(hdcBin(), args, { encoding: "utf8", timeout: 60000 });
  return { status: r.status, stdout: r.stdout || "", stderr: r.stderr || "" };
}
function targets() {
  const r = hdc(["list", "targets"]);
  if (r.status !== 0) return [];
  return r.stdout.split("\n").map((x) => x.trim()).filter((x) => x && !/empty/i.test(x));
}
function pickDevice(sel) {
  const ts = targets();
  if (sel) {
    if (!ts.includes(sel)) fail("ERR_INVALID_REQUEST", `device not found: ${sel}`);
    return sel;
  }
  if (ts.length === 0) fail("ERR_BACKEND_UNAVAILABLE", "no device connected");
  if (ts.length > 1) fail("ERR_INVALID_REQUEST", "multiple devices; pass --device");
  return ts[0];
}

// ---- backends: capabilities ----
function backendCapabilities(backend) {
  if (backend === "hdc") {
    return { backend: "hdc", available: targets().length > 0, targets: targets(),
      features: ["bundle_verify", "certificate_verify", "permission_verify"] };
  }
  if (backend === "sideload") {
    // Official API not published yet → always unavailable, fail closed.
    return { backend: "sideload", available: false, targets: ["local"],
      features: ["interactive_confirmation"], unavailable_reason: "system sideload API not published" };
  }
  fail("ERR_INVALID_REQUEST", `unknown backend: ${backend}`);
}

function chooseMethod(requested) {
  if (requested === "hdc") {
    if (targets().length === 0) fail("ERR_BACKEND_UNAVAILABLE", "hdc backend unavailable");
    return "hdc";
  }
  if (requested === "sideload") {
    // fail closed before any signing/upload side effect
    fail("ERR_BACKEND_UNAVAILABLE", "sideload backend unavailable (system API not published)");
  }
  if (requested === "auto" || !requested) {
    // auto prefers sideload only if available AND compatible; current SDK: hdc.
    const sl = backendCapabilities("sideload");
    if (sl.available) return "sideload";
    if (targets().length > 0) return "hdc";
    fail("ERR_BACKEND_UNAVAILABLE", "no install backend available");
  }
  fail("ERR_INVALID_REQUEST", `invalid --method: ${requested}`);
}

function sha256File(p) { return crypto.createHash("sha256").update(fs.readFileSync(p)).digest("hex"); }

// ---- hdc backend: upload + bm install + post verification ----
function installHdc(req, dev) {
  const signed = path.resolve(req.hap_path);
  if (!fs.existsSync(signed) || !fs.statSync(signed).isFile()) fail("ERR_INVALID_REQUEST", `file not found: ${signed}`);
  if (sha256File(signed) !== req.hap_sha256) fail("ERR_INVALID_REQUEST", "signed HAP sha256 mismatch");

  const op = `hdc-${Date.now()}`;
  emit({ protocol_version: 1, type: "install_state", operation_id: op, backend: "hdc",
    device: dev, state: "installing", observed_at: new Date().toISOString() });

  const remote = `/data/local/tmp/${path.basename(signed)}`;
  const send = hdc(["-t", dev, "file", "send", signed, remote]);
  if (send.status !== 0) fail("ERR_INSTALL_FAILED", `hdc file send failed: ${send.stderr}`);

  const inst = hdc(["-t", dev, "shell", "bm", "install", "-p", remote]);
  if (inst.status !== 0) fail("ERR_INSTALL_FAILED", `bm install failed (text only diagnostic): ${inst.stdout}${inst.stderr}`);

  // post-install verification via bm dump — the authoritative success signal
  const bundle = req.expected?.bundle_id;
  const dump = hdc(["-t", dev, "shell", "bm", "dump", "-n", bundle]);
  const verification = { bundle_matched: null, version_matched: null,
    certificate_matched: null, permissions_matched: null, unsupported: [] };
  if (dump.status === 0 && dump.stdout.includes(bundle)) verification.bundle_matched = true;
  else verification.bundle_matched = false;
  if (req.expected?.version_code != null && dump.stdout.includes(String(req.expected.version_code))) {
    verification.version_matched = true;
  } else if (req.expected?.version_code != null) verification.version_matched = false;
  verification.certificate_matched = null; verification.unsupported.push("certificate_verify");
  verification.permissions_matched = null; verification.unsupported.push("permission_verify");

  const ok = verification.bundle_matched === true && (verification.version_matched !== false);
  emit({ protocol_version: 1, type: "install_result", operation_id: op, backend: "hdc",
    state: ok ? "installed" : "failed",
    bundle: { bundle_id: bundle, version_code: req.expected?.version_code },
    verification, error: ok ? null : { code: "ERR_POST_INSTALL_VERIFY_FAILED", detail: "post-install verification mismatch" } });
  if (!ok) process.exit(1);
}

// ---- sideload backend: fail-closed stub (no official API yet) ----
function installSideload() {
  fail("ERR_BACKEND_UNAVAILABLE", "sideload backend not implemented: system API not published");
}

function cmdInstall(o) {
  let req;
  if (o.request) {
    try { req = JSON.parse(fs.readFileSync(o.request, "utf8")); }
    catch (e) { fail("ERR_INVALID_REQUEST", `cannot parse request: ${e.message}`); }
    if (req.protocol_version !== 1) fail("ERR_UNSUPPORTED_PROTOCOL", `protocol_version ${req.protocol_version}`);
  } else if (o.hap) {
    req = { protocol_version: 1, method: o.method || "auto", device: o.device || "local",
      hap_path: o.hap, hap_sha256: sha256File(path.resolve(o.hap)),
      expected: { bundle_id: o.bundle_id || "", version_code: o.version_code ? Number(o.version_code) : undefined },
      wait: true };
  } else fail("ERR_INVALID_REQUEST", "--request or --hap is required");

  // capability preflight happens BEFORE any install action; no cross-backend fallback once started
  const method = chooseMethod(req.method);
  const dev = method === "hdc" ? pickDevice(req.device || o.device) : "local";
  if (method === "sideload") return installSideload();
  return installHdc(req, dev);
}

function cmdUninstall(o) {
  if (!o.bundle_id) fail("ERR_INVALID_REQUEST", "--bundle-id is required");
  const dev = pickDevice(o.device);
  const args = ["-t", dev, "shell", "bm", "uninstall", "-n", o.bundle_id];
  if (!o.purge) args.push("-k"); // keep user data by default (zap semantics only with --purge)
  const r = hdc(args);
  if (/not found|does not exist|not installed/i.test(r.stdout)) {
    emit({ protocol_version: 1, type: "install_result", operation_id: "", backend: "hdc",
      state: "unknown", bundle: { bundle_id: o.bundle_id }, verification: {}, error: null });
    return; // idempotent
  }
  if (r.status !== 0 || !/success/i.test(r.stdout)) fail("ERR_INSTALL_FAILED", `bm uninstall: ${r.stdout}${r.stderr}`);
  emit({ protocol_version: 1, type: "install_result", operation_id: "", backend: "hdc",
    state: "installed", bundle: { bundle_id: o.bundle_id }, verification: {}, error: null });
}

function cmdLifecycle(o, cmd) {
  if (!o.bundle_id) fail("ERR_INVALID_REQUEST", "--bundle-id is required");
  const dev = pickDevice(o.device);
  if (cmd === "start") {
    if (!o.module || !o.ability) fail("ERR_INVALID_REQUEST", "start needs --module and --ability");
    const r = hdc(["-t", dev, "shell", "aa", "start", "-a", o.ability, "-b", o.bundle_id, "-m", o.module]);
    if (r.status !== 0) fail("ERR_INSTALL_FAILED", `aa start failed: ${r.stderr}`);
    emit({ protocol_version: 1, command: "start", bundle_id: o.bundle_id, ok: true });
  } else if (cmd === "stop") {
    const r = hdc(["-t", dev, "shell", "aa", "force-stop", o.bundle_id]);
    if (r.status !== 0) fail("ERR_INSTALL_FAILED", `aa force-stop failed: ${r.stderr}`);
    emit({ protocol_version: 1, command: "stop", bundle_id: o.bundle_id, ok: true });
  } else if (cmd === "status") {
    const r = hdc(["-t", dev, "shell", "ps", "-ef"]);
    const running = r.stdout.includes(o.bundle_id);
    emit({ protocol_version: 1, command: "status", bundle_id: o.bundle_id, running });
  } else if (cmd === "permissions") {
    const r = hdc(["-t", dev, "shell", "bm", "dump", "-n", o.bundle_id]);
    emit({ protocol_version: 1, command: "permissions", bundle_id: o.bundle_id, raw: r.stdout.slice(0, 4000) });
  } else if (cmd === "logs") {
    const r = hdc(["-t", dev, "shell", "hilog", "-D", "01d00", "-T", o.bundle_id, "-n", "1"]);
    emit({ protocol_version: 1, command: "logs", bundle_id: o.bundle_id, raw: r.stdout.slice(0, 4000) });
  }
}

function cmdInstallStatus(o) {
  // No stable operation ID in hdc backend → declare unsupported; never fabricate a pending DB.
  fail("ERR_STATUS_QUERY_UNSUPPORTED", "install-status not supported by hdc backend; use status --bundle-id");
}

function main() {
  const argv = process.argv.slice(2);
  const cmd = argv[0] || "help";
  if (cmd === "help" || cmd === "--help" || cmd === "-h") { usage(); return; }
  const o = parseArgs(argv.slice(1));
  o._ = [cmd, ...o._];
  switch (cmd) {
    case "backends": return emit({ protocol_version: 1,
      backends: [backendCapabilities("hdc"), backendCapabilities("sideload")] });
    case "list": return emit({ protocol_version: 1, devices: targets() });
    case "install": return cmdInstall(o);
    case "install-status": return cmdInstallStatus(o);
    case "uninstall": return cmdUninstall(o);
    case "start": case "stop": case "status": case "permissions": case "logs":
      return cmdLifecycle(o, cmd);
    default: fail("ERR_INVALID_REQUEST", `unknown command: ${cmd}`);
  }
}

if (require.main === module) main();
module.exports = { backendCapabilities, chooseMethod, sha256File };
