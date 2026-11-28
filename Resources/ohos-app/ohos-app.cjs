#!/usr/bin/env node
"use strict";

// ohos-app: orchestration layer. It reads a desktop formula's app.json
// descriptor and drives ohos-hap (sign) + ohos-device (install) via their L0
// process contracts. It NEVER implements signing, device I/O, assembly, or
// host-service management, and it never calls <app> install (no loopback).
// Commands are explicit and synchronous; failures are non-zero with no pending
// queue and no background retry.

const fs = require("node:fs");
const path = require("node:path");
const crypto = require("node:crypto");
const { spawnSync } = require("node:child_process");

function fail(code, msg) {
  process.stdout.write(JSON.stringify({ protocol_version: 1, type: "error", error: { code, detail: msg } }) + "\n");
  process.exit(1);
}
function out(obj) { process.stdout.write(JSON.stringify(obj) + "\n"); }
function usage() {
  process.stdout.write(`Usage:
  ohos-app list [--json]
  ohos-app info <id> [--json]
  ohos-app configure <id>
  ohos-app install <id> [--device SEL] [--variant NAME] [--signing-profile NAME]
                 [--method hdc|sideload|auto] [--start] [--json]
  ohos-app uninstall <id> [--device SEL] [--purge]
  ohos-app start|stop|status <id> [--device SEL] [--json]
  ohos-app logs <id> [--device SEL]
  ohos-app doctor [<id>] [--json]
  ohos-app cache list|prune
`);
}

function parseArgs(args) {
  const o = { _: [] };
  for (let i = 0; i < args.length; i += 1) {
    const k = args[i];
    if (k === "--help" || k === "-h") { o.help = true; continue; }
    if (["--start", "--purge", "--json"].includes(k)) { o[k.slice(2)] = true; continue; }
    if (k.startsWith("--")) {
      const v = args[++i];
      if (!v) fail("ERR_INVALID_REQUEST", `missing value for ${k}`);
      o[k.slice(2).replaceAll("-", "_")] = v;
    } else o._.push(k);
  }
  return o;
}

function prefix() { return process.env.HOMEBREW_PREFIX || "/opt/homebrew"; }
function canonicalIdFromDir(dir) {
  // dir looks like <prefix>/opt/<formula>/share/<formula>/ohos/app.json
  const m = dir.match(/\/opt\/([^/]+)\/share\/[^/]+\/ohos\/app\.json$/);
  return m ? `social4hyq/core/${m[1]}` : null;
}
function enumerateDescriptors() {
  const opt = path.join(prefix(), "opt");
  const found = [];
  if (!fs.existsSync(opt)) return found;
  for (const formula of fs.readdirSync(opt)) {
    const candidate = path.join(opt, formula, "share", formula, "ohos", "app.json");
    if (fs.existsSync(candidate)) found.push({ formula, path: candidate });
  }
  return found;
}
function shortToId(short) {
  if (short.includes("/")) return short; // already canonical
  return `social4hyq/core/${short}`;
}
function loadDescriptor(id) {
  const entries = enumerateDescriptors();
  const e = entries.find((x) => shortToId(x.formula) === id || x.formula === id);
  if (!e) fail("ERR_INVALID_REQUEST", `no installed desktop formula for id: ${id}`);
  let doc;
  try { doc = JSON.parse(fs.readFileSync(e.path, "utf8")); }
  catch (err) { fail("ERR_INVALID_REQUEST", `cannot parse app.json: ${err.message}`); }
  if (doc.schema_version !== 1) fail("ERR_UNSUPPORTED_PROTOCOL", `schema_version ${doc.schema_version}`);
  if (doc.id !== shortToId(e.formula)) fail("ERR_INVALID_REQUEST", `descriptor id mismatch: ${doc.id}`);
  return { doc, dir: path.dirname(e.path) };
}
function resolvePath(base, rel) {
  // allow only paths that resolve inside the canonical keg (prefix/opt/<formula>)
  const p = path.resolve(base, rel);
  const optRoot = path.resolve(prefix(), "opt");
  if (!p.startsWith(optRoot + path.sep)) fail("ERR_PATH_ESCAPE", `path escapes opt root: ${rel}`);
  return p;
}
function sha256File(p) {
  if (!fs.existsSync(p) || !fs.statSync(p).isFile()) fail("ERR_INVALID_REQUEST", `file not found: ${p}`);
  return crypto.createHash("sha256").update(fs.readFileSync(p)).digest("hex");
}

function runPlugin(dir, relativePath, requestPath, role) {
  const plugin = resolvePath(dir, relativePath);
  if (!fs.existsSync(plugin) || !fs.statSync(plugin).isFile()) {
    fail("ERR_INVALID_REQUEST", `${role} plugin not found: ${relativePath}`);
  }
  const result = spawnSync(process.execPath, [plugin, "--protocol", "1", "--request", requestPath], {
    stdio: "inherit", timeout: 300000,
    env: { PATH: process.env.PATH || "", HOME: process.env.HOME || "" },
  });
  if (result.error || result.status !== 0) {
    fail("ERR_INVALID_REQUEST", `${role} plugin failed (${result.status})`);
  }
}

function hostContext() {
  return {
    home: process.env.HOME || "",
    path: process.env.PATH || "",
    xdg_config: process.env.XDG_CONFIG_HOME || "",
    xdg_data: process.env.XDG_DATA_HOME || "",
    xdg_state: process.env.XDG_STATE_HOME || "",
  };
}

function selectDevice(devBin, requested) {
  if (requested) return requested;
  const result = spawnSync(devBin, ["list", "--json"], { encoding: "utf8", timeout: 30000 });
  if (result.error || result.status !== 0) fail("ERR_BACKEND_UNAVAILABLE", "cannot enumerate devices");
  let doc;
  try { doc = JSON.parse((result.stdout || "").trim().split("\n").pop()); }
  catch { fail("ERR_BACKEND_UNAVAILABLE", "device list returned invalid JSON"); }
  const devices = Array.isArray(doc.devices) ? doc.devices : [];
  if (devices.length === 0) return "local";
  if (devices.length > 1) fail("ERR_INVALID_REQUEST", `multiple devices connected; pass --device (found ${devices.length})`);
  return devices[0];
}

function hapSigningEnv(hapBin, profileName) {
  const env = { ...process.env };
  if (env.HAP_SIGN_TOOL) return env;

  // Let ohos-hap's profile-specific signer take precedence over auto-discovery.
  const profileResult = spawnSync(hapBin, ["profile", "show", profileName], {
    encoding: "utf8", timeout: 30000, env,
  });
  if (profileResult.status === 0) {
    try {
      if (JSON.parse(profileResult.stdout || "null")?.signer_path) return env;
    } catch {}
  }

  const bundledSigner = path.join(prefix(), "opt", "ohos-sdk-toolchains", "lib", "hap-sign-tool");
  if (fs.existsSync(bundledSigner) && fs.statSync(bundledSigner).isFile()) {
    env.HAP_SIGN_TOOL = bundledSigner;
  }
  return env;
}

function cmdList() {
  const items = enumerateDescriptors().map((e) => {
    const d = JSON.parse(fs.readFileSync(e.path, "utf8"));
    return { id: d.id, version_name: d.artifact?.version_name, bundle_id: d.artifact?.bundle_id };
  });
  out({ protocol_version: 1, apps: items });
}
function cmdInfo(o) {
  const id = o._[1]; if (!id) fail("ERR_INVALID_REQUEST", "info needs <id>");
  const { doc } = loadDescriptor(shortToId(id));
  out({ protocol_version: 1, id: doc.id, artifact: doc.artifact, variants: doc.variants, requires: doc.requires });
}
function cmdConfigure(o) {
  const id = o._[1]; if (!id) fail("ERR_INVALID_REQUEST", "configure needs <id>");
  const { doc, dir } = loadDescriptor(shortToId(id));
  const plugin = doc.host_integration || (doc.hooks?.host_integration);
  if (!plugin) fail("ERR_INVALID_REQUEST", `${doc.id} has no host-integration plugin`);
  const exec = plugin.exec || (Array.isArray(plugin) ? plugin : null);
  if (!exec) fail("ERR_INVALID_REQUEST", "host-integration plugin has no exec array");
  const r = spawnSync(exec[0], exec.slice(1), { stdio: "inherit", timeout: 120000 });
  if (r.status !== 0) fail("ERR_INVALID_REQUEST", `configure plugin failed (${r.status})`);
  out({ protocol_version: 1, command: "configure", id: doc.id, ok: true });
}
function cmdInstall(o) {
  const id = o._[1]; if (!id) fail("ERR_INVALID_REQUEST", "install needs <id>");
  const { doc, dir } = loadDescriptor(shortToId(id));

  // variant selection: default unless --variant; must be declared
  const variant = o.variant || doc.variants?.default || "basic";
  if (!doc.variants?.definitions?.[variant]) fail("ERR_INVALID_REQUEST", `undeclared variant: ${variant}`);
  const unsigned = resolvePath(dir, doc.artifact.path);
  const unsignedSha = sha256File(unsigned);
  if (unsignedSha !== doc.artifact.sha256) fail("ERR_INVALID_REQUEST", "unsigned HAP sha256 mismatch (bottle altered?)");

  const hapBin = process.env.OHOS_APP_HAP_BIN || path.join(prefix(), "bin/ohos-hap");
  const devBin = process.env.OHOS_APP_DEVICE_BIN || path.join(prefix(), "bin/ohos-device");
  if (!fs.existsSync(hapBin)) fail("ERR_BACKEND_UNAVAILABLE", `ohos-hap not found: ${hapBin}`);
  if (!fs.existsSync(devBin)) fail("ERR_BACKEND_UNAVAILABLE", `ohos-device not found: ${devBin}`);
  const selectedDevice = selectDevice(devBin, o.device);

  const variantDef = doc.variants.definitions[variant];
  let moduleOverlay = null;
  if (variantDef.module_overlay && doc.assembly?.plugin) {
    moduleOverlay = resolvePath(dir, variantDef.module_overlay);
    // Older desktop formulas placed module-acl.json beside ohos/app.json while
    // storing a bare filename in the descriptor. Accept that layout during the
    // transition; new descriptors should use an explicit relative path.
    if (!fs.existsSync(moduleOverlay) && !variantDef.module_overlay.includes("/")) {
      const adjacent = resolvePath(path.dirname(dir), variantDef.module_overlay);
      if (fs.existsSync(adjacent)) moduleOverlay = adjacent;
    }
    const overlaySha = sha256File(moduleOverlay);
    if (!variantDef.sha256 || overlaySha !== variantDef.sha256) {
      fail("ERR_INVALID_REQUEST", `variant module_overlay sha256 mismatch: ${variant}`);
    }
  }
  if (doc.personalization && !doc.assembly?.plugin) {
    fail("ERR_INVALID_REQUEST", "personalization requires an assembly plugin");
  }
  const stage = path.join(dir, `.ohos-app-stage-${process.pid}-${crypto.randomBytes(6).toString("hex")}`);
  fs.mkdirSync(stage, { recursive: true, mode: 0o700 });
  process.on("exit", () => { try { fs.rmSync(stage, { recursive: true, force: true }); } catch {} });
  const host = hostContext();
  let personalizedTree = null;
  if (doc.personalization?.plugin) {
    personalizedTree = path.join(stage, "personalized");
    fs.mkdirSync(personalizedTree, { mode: 0o700 });
    const stateRoot = host.xdg_state || path.join(host.home, ".local", "state");
    const declaredConfigRoot = doc.personalization.config_root || "$XDG_STATE_HOME/ohos-app/integrations/" +
      doc.id.replaceAll("/", "_");
    const configRoot = path.resolve(declaredConfigRoot.replaceAll("$XDG_STATE_HOME", stateRoot));
    const personalizeReq = {
      protocol_version: 1, config_root: configRoot, output_tree: personalizedTree, host,
    };
    const requestPath = path.join(stage, "personalization-request.json");
    fs.writeFileSync(requestPath, JSON.stringify(personalizeReq), { mode: 0o600 });
    runPlugin(dir, doc.personalization.plugin, requestPath, "personalizer");
  }

  // L2 assembly is delegated to the app's assembler plugin. The engine owns
  // artifact/overlay verification and passes only verified paths plus the
  // selected variant and private personalized tree.
  let toSign = unsigned;
  if (doc.assembly?.plugin) {
    const req = {
      protocol_version: 1,
      unsigned_hap: unsigned,
      out_hap: path.join(stage, "assembled.hap"),
      variant,
      variant_definition: { module_overlay: moduleOverlay, sha256: variantDef.sha256 || null },
      abi: doc.artifact?.abis?.[0] || "arm64-v8a",
      api: doc.artifact?.api || null,
      tree: path.join(stage, "tree"),
      personalized_tree: personalizedTree,
      config: doc.assembly.config || {},
    };
    fs.mkdirSync(req.tree, { mode: 0o700 });
    const rf = path.join(stage, "assembly-request.json");
    fs.writeFileSync(rf, JSON.stringify(req), { mode: 0o600 });
    runPlugin(dir, doc.assembly.plugin, rf, "assembler");
    toSign = req.out_hap;
    if (!fs.existsSync(toSign)) fail("ERR_INVALID_REQUEST", "assembler produced no output");
  }

  // L3 sign: build SigningRequest, call ohos-hap.
  const signedOut = path.join(dir, `.ohos-app-signed-${process.pid}.hap`);
  const signingProfileName = o.signing_profile || doc.signing_profile || "default";
  const signReq = { protocol_version: 1, input_hap: toSign,
    input_sha256: sha256File(toSign), output_path: signedOut,
    signing_profile_name: signingProfileName,
    expected: { bundle_id: doc.artifact.bundle_id, version_code: doc.artifact.version_code } };
  const signReqFile = path.join(dir, `.ohos-app-signreq-${process.pid}.json`);
  const signResFile = path.join(dir, `.ohos-app-signres-${process.pid}.json`);
  const instReqFile = path.join(dir, `.ohos-app-instreq-${process.pid}.json`);
  const ephemeralFiles = [signReqFile, signResFile, instReqFile, signedOut];
  process.on("exit", () => {
    for (const file of ephemeralFiles) { try { fs.rmSync(file, { force: true }); } catch {} }
  });
  fs.writeFileSync(signReqFile, JSON.stringify(signReq), { mode: 0o600 });
  const sr = spawnSync(hapBin, ["sign", "--request", signReqFile, "--result", signResFile], {
    stdio: "inherit", timeout: 300000, env: hapSigningEnv(hapBin, signingProfileName),
  });
  if (sr.status !== 0) fail("ERR_SIGN_FAILED", "ohos-hap sign failed");
  if (!fs.existsSync(signedOut)) fail("ERR_SIGN_FAILED", "no signed HAP from ohos-hap");

  // L4 install: build InstallRequest, call ohos-device, stream its NDJSON.
  const instReq = { protocol_version: 1, method: o.method || "auto", device: selectedDevice,
    hap_path: signedOut, hap_sha256: sha256File(signedOut),
    expected: { bundle_id: doc.artifact.bundle_id, version_name: doc.artifact.version_name,
      version_code: doc.artifact.version_code }, wait: true };
  fs.writeFileSync(instReqFile, JSON.stringify(instReq), { mode: 0o600 });
  const ir = spawnSync(devBin, ["install", "--request", instReqFile], { encoding: "utf8", timeout: 600000 });
  if (ir.stdout) process.stdout.write(ir.stdout);
  if (ir.stderr) process.stderr.write(ir.stderr);
  if (ir.status !== 0) fail("ERR_INSTALL_FAILED", "ohos-device install failed");

  const terminal = (ir.stdout || "").trim().split("\n").filter(Boolean).map((l) => {
    try { return JSON.parse(l); } catch { return null; }
  }).filter((x) => x && x.type === "install_result").pop();
  if (!terminal || terminal.state !== "installed") fail("ERR_INSTALL_FAILED", "no successful install_result from device");

  // optional --start: device aa start only, after success
  if (o.start) {
    const st = spawnSync(devBin, ["start", "--bundle-id", doc.artifact.bundle_id,
      "--module", doc.launch.module, "--ability", doc.launch.ability], { stdio: "inherit" });
    if (st.status !== 0) fail("ERR_INSTALL_FAILED", "device start failed (install succeeded)");
  }
  // cleanup temp artifacts (no persistent state)
  for (const f of [signReqFile, signResFile, instReqFile]) { try { fs.unlinkSync(f); } catch {} }
  try { fs.unlinkSync(signedOut); } catch {}
  try { fs.rmSync(stage, { recursive: true, force: true }); } catch {}
  out({ protocol_version: 1, command: "install", id: doc.id, variant, state: "installed" });
}
function cmdUninstall(o) {
  const id = o._[1]; if (!id) fail("ERR_INVALID_REQUEST", "uninstall needs <id>");
  const { doc } = loadDescriptor(shortToId(id));
  const devBin = process.env.OHOS_APP_DEVICE_BIN || path.join(prefix(), "bin/ohos-device");
  const args = ["uninstall", "--bundle-id", doc.artifact.bundle_id];
  if (o.device) args.push("--device", o.device);
  if (o.purge) args.push("--purge");
  const r = spawnSync(devBin, args, { stdio: "inherit" });
  if (r.status !== 0) fail("ERR_INSTALL_FAILED", "device uninstall failed");
  out({ protocol_version: 1, command: "uninstall", id: doc.id, ok: true });
}
function cmdLifecycle(o, cmd) {
  const id = o._[1]; if (!id) fail("ERR_INVALID_REQUEST", `${cmd} needs <id>`);
  const { doc } = loadDescriptor(shortToId(id));
  const devBin = process.env.OHOS_APP_DEVICE_BIN || path.join(prefix(), "bin/ohos-device");
  const args = [cmd, "--bundle-id", doc.artifact.bundle_id];
  if (o.device) args.push("--device", o.device);
  if (cmd === "start") { args.push("--module", doc.launch.module, "--ability", doc.launch.ability); }
  const r = spawnSync(devBin, args, { stdio: "inherit" });
  if (r.status !== 0) fail("ERR_INVALID_REQUEST", `device ${cmd} failed`);
}
function cmdDoctor(o) {
  const bins = { "ohos-hap": process.env.OHOS_APP_HAP_BIN || path.join(prefix(), "bin/ohos-hap"),
    "ohos-device": process.env.OHOS_APP_DEVICE_BIN || path.join(prefix(), "bin/ohos-device") };
  const status = {};
  for (const [k, v] of Object.entries(bins)) status[k] = fs.existsSync(v);
  out({ protocol_version: 1, tools: status, apps: enumerateDescriptors().length });
}
function cmdCache(o) {
  const sub = o._[1];
  if (sub === "list") out({ protocol_version: 1, entries: [] });
  else if (sub === "prune") out({ protocol_version: 1, pruned: 0 });
  else fail("ERR_INVALID_REQUEST", "cache needs list|prune");
}

function main() {
  const argv = process.argv.slice(2);
  const cmd = argv[0] || "help";
  if (cmd === "help" || cmd === "--help" || cmd === "-h") { usage(); return; }
  const o = parseArgs(argv.slice(1));
  o._ = [cmd, ...o._];
  switch (cmd) {
    case "list": return cmdList();
    case "info": return cmdInfo(o);
    case "configure": return cmdConfigure(o);
    case "install": return cmdInstall(o);
    case "uninstall": return cmdUninstall(o);
    case "start": case "stop": case "status": case "logs": return cmdLifecycle(o, cmd);
    case "doctor": return cmdDoctor(o);
    case "cache": return cmdCache(o);
    default: fail("ERR_INVALID_REQUEST", `unknown command: ${cmd}`);
  }
}
if (require.main === module) main();
module.exports = { enumerateDescriptors, loadDescriptor, resolvePath, shortToId };
