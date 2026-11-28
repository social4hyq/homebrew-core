#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

function fail(message) {
  process.stderr.write(`module-overlay: ${message}\n`);
  process.exit(1);
}

function argument(name) {
  const index = process.argv.indexOf(name);
  if (index < 0 || !process.argv[index + 1]) fail(`missing ${name}`);
  return process.argv[index + 1];
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, { stdio: "inherit", ...options });
  if (result.error) fail(`${command}: ${result.error.message}`);
  if (result.status !== 0) fail(`${command} exited with ${result.status}`);
}

if (argument("--protocol") !== "1") fail("unsupported protocol version");
const request = JSON.parse(fs.readFileSync(argument("--request"), "utf8"));
const overlayPath = request.variant_definition?.module_overlay;
if (!overlayPath || !fs.existsSync(overlayPath)) fail("module overlay is missing");

const extracted = path.join(request.tree, "module-overlay-hap");
fs.mkdirSync(extracted, { mode: 0o700 });
run("unzip", ["-q", request.unsigned_hap, "-d", extracted]);

const modulePath = path.join(extracted, "module.json");
let base;
let overlay;
try {
  base = JSON.parse(fs.readFileSync(modulePath, "utf8"));
  overlay = JSON.parse(fs.readFileSync(overlayPath, "utf8"));
} catch (error) {
  fail(`cannot parse module manifest: ${error.message}`);
}

if (!base.app?.bundleName || base.app.bundleName !== overlay.app?.bundleName) {
  fail("overlay bundleName does not match the HAP");
}
if (!base.module?.name || base.module.name !== overlay.module?.name) {
  fail("overlay module name does not match the HAP");
}
const permissions = overlay.module.requestPermissions;
if (!Array.isArray(permissions) || permissions.some((item) => !item || typeof item.name !== "string" || !item.name)) {
  fail("overlay requestPermissions must be an array of named permissions");
}
const names = permissions.map((item) => item.name);
if (new Set(names).size !== names.length) fail("overlay contains duplicate permissions");

fs.copyFileSync(overlayPath, modulePath);
fs.rmSync(request.out_hap, { force: true });
// HarmonyOS rejects HAPs with ZIP directory entries during signature
// verification. Keep file payloads intact and omit those entries.
run("zip", ["-q", "-r", "-D", request.out_hap, "."], { cwd: extracted });
