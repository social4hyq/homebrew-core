#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const path = require("node:path");
const { execFileSync } = require("node:child_process");
const { createRequire } = require("node:module");

// `--expiry <build-profile.json5>` prints the whole days left on the local debug
// profile and nothing when it cannot be determined (the caller treats that as
// "unknown", never as an error).
function profileDaysLeft(buildProfile) {
  try {
    const json5 = createRequire(process.env.DEVECO_CLI_JS)("json5");
    const config = json5.parse(fs.readFileSync(buildProfile, "utf8"));
    const signing = config.app?.signingConfigs?.find(item => item.name === "default") || config.app?.signingConfigs?.[0];
    const file = signing?.material?.profile;
    if (!file) return null;
    const p7b = fs.readFileSync(path.resolve(path.dirname(buildProfile), file), "latin1");
    const notAfter = /"not-after"\s*:\s*(\d+)/.exec(p7b);
    return notAfter ? Math.floor((Number(notAfter[1]) * 1000 - Date.now()) / 86400000) : null;
  } catch {
    return null;
  }
}

if (process.argv[2] === "--expiry") {
  const days = profileDaysLeft(process.argv[3] ?? "");
  if (days !== null) console.log(days);
  process.exit(0);
}

try {
  const [hap, bundle, project] = process.argv.slice(2);
  const manifest = JSON.parse(execFileSync("unzip", ["-p", hap, "module.json"], { encoding: "utf8" }));
  if (manifest.app?.bundleName !== bundle) throw new Error("HAP bundle does not match --bundle-id");
  const requests = manifest.module?.requestPermissions ?? [];
  if (!Array.isArray(requests) || requests.some(p => typeof p.name !== "string" || !p.name)) {
    throw new Error("invalid HAP requestPermissions");
  }
  if (project) {
    const json5 = createRequire(process.env.DEVECO_CLI_JS)("json5");
    const file = path.join(project, "entry/src/main/module.json5");
    const config = json5.parse(fs.readFileSync(file, "utf8"));
    // Only names are needed for profile generation. Resource references and
    // ability names in the HAP belong to its project, not this signing stub.
    config.module.requestPermissions = [...new Set(requests.map(p => p.name))].map(name => ({ name }));
    const temporary = file + ".tmp";
    try {
      fs.writeFileSync(temporary, JSON.stringify(config, null, 2) + "\n");
      fs.renameSync(temporary, file);
    } finally {
      fs.rmSync(temporary, { force: true });
    }
  }
} catch (error) {
  console.error(`app-installer: ${error.message}`);
  process.exitCode = 1;
}
