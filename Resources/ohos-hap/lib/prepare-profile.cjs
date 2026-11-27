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

// A HAP that carries zip directory entries (libs/, resources/, ...) is signed
// without error but then rejected by `bm install` with 9568393 "verify code
// signature failed": the installer finds no native-library signatures in the
// code-sign block. hvigor-built HAPs have no directory entries; hand-zipped
// ones usually do. `--strip-dirs <in.hap> <out.hap>` writes a copy without
// them and prints how many it removed (nothing is written when there are
// none). The other entries are copied byte for byte, never recompressed, so
// the native libraries and their .codesign sections stay identical.
function stripDirectoryEntries(input, output) {
  const buf = fs.readFileSync(input);
  let eocd = -1;
  for (let i = buf.length - 22; i >= Math.max(0, buf.length - 22 - 0xffff); i -= 1) {
    if (buf.readUInt32LE(i) === 0x06054b50) { eocd = i; break; }
  }
  if (eocd < 0) throw new Error("not a zip file");
  const total = buf.readUInt16LE(eocd + 10);
  const cdSize = buf.readUInt32LE(eocd + 12);
  const cdOffset = buf.readUInt32LE(eocd + 16);
  if (total === 0xffff || cdSize === 0xffffffff || cdOffset === 0xffffffff) throw new Error("zip64 is not supported");

  const entries = [];
  let pos = cdOffset;
  for (let n = 0; n < total; n += 1) {
    if (buf.readUInt32LE(pos) !== 0x02014b50) throw new Error("corrupt zip central directory");
    const nameLength = buf.readUInt16LE(pos + 28);
    const length = 46 + nameLength + buf.readUInt16LE(pos + 30) + buf.readUInt16LE(pos + 32);
    entries.push({
      central: buf.subarray(pos, pos + length),
      offset: buf.readUInt32LE(pos + 42),
      directory: nameLength > 0 && buf[pos + 45 + nameLength] === 0x2f,
    });
    pos += length;
  }
  if (pos !== cdOffset + cdSize) throw new Error("corrupt zip central directory");
  if (!entries.some(entry => entry.directory)) return 0;

  // An entry's data runs from its local header to the next entry's header.
  const byOffset = [...entries].sort((a, b) => a.offset - b.offset);
  if (byOffset[0].offset !== 0) throw new Error("unexpected data before the first zip entry");
  byOffset.forEach((entry, index) => {
    entry.end = index + 1 < byOffset.length ? byOffset[index + 1].offset : cdOffset;
    if (entry.end <= entry.offset) throw new Error("overlapping zip entries");
  });

  const kept = entries.filter(entry => !entry.directory);
  const locals = [];
  const centrals = [];
  let offset = 0;
  for (const entry of kept) {
    const central = Buffer.from(entry.central);
    central.writeUInt32LE(offset, 42);
    locals.push(buf.subarray(entry.offset, entry.end));
    centrals.push(central);
    offset += entry.end - entry.offset;
  }
  const centralSize = centrals.reduce((sum, central) => sum + central.length, 0);
  const tail = Buffer.from(buf.subarray(eocd));
  tail.writeUInt16LE(kept.length, 8);
  tail.writeUInt16LE(kept.length, 10);
  tail.writeUInt32LE(centralSize, 12);
  tail.writeUInt32LE(offset, 16);
  fs.writeFileSync(output, Buffer.concat([...locals, ...centrals, tail]), { mode: 0o600 });
  return entries.length - kept.length;
}

if (process.argv[2] === "--strip-dirs") {
  try {
    console.log(stripDirectoryEntries(process.argv[3], process.argv[4]));
    process.exit(0);
  } catch (error) {
    console.error(`ohos-hap: ${error.message}`);
    process.exit(1);
  }
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
  console.error(`ohos-hap: ${error.message}`);
  process.exitCode = 1;
}
