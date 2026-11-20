#!/usr/bin/env node
"use strict";

// Reports whether the HAP installed on the device actually got the permissions
// it asked for. `bm dump -n <bundle>` prints a header line before the bundle
// JSON, and its `reqPermissionStates` are 0 for granted and -1 for permissions
// the user still has to grant at runtime (grantMode `user_grant`, e.g. paste or
// screen capture): those are not installation failures. Only permissions the
// installer/profile grants at install time (`system_grant`, the ACL ones) must
// be granted.
//
// Usage: check-permissions.cjs <dump.json|-> <PermissionDefinitions.json> [<module-acl.json>]
//
// With a module-acl.json, every permission it requests must also be present on
// the device: a missing one means the ACL variant was not the one installed.
// Exit 0 only when no install-time permission is missing.

const fs = require("node:fs");

function fail(message) {
  console.error(`app-installer: ${message}`);
  process.exit(2);
}

// bm dump prints "<bundle>:" (and sometimes trailers) around the JSON object.
function readDump(text) {
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start < 0 || end <= start) throw new Error("no JSON object in bm dump output");
  return JSON.parse(text.slice(start, end + 1));
}

const [dumpPath, definitionsPath, aclPath] = process.argv.slice(2);
if (!dumpPath || !definitionsPath) {
  fail("usage: check-permissions.cjs <dump> <PermissionDefinitions.json> [<module-acl.json>]");
}

let dump;
let definitions;
try {
  const raw = dumpPath === "-" ? fs.readFileSync(0, "utf8") : fs.readFileSync(dumpPath, "utf8");
  dump = readDump(raw);
  definitions = JSON.parse(fs.readFileSync(definitionsPath, "utf8"));
} catch (error) {
  fail(error.message);
}

const modes = new Map((definitions.definePermissions ?? []).map((entry) => [entry.name, entry.grantMode]));
const names = Array.isArray(dump.reqPermissions) ? dump.reqPermissions : [];
const states = Array.isArray(dump.reqPermissionStates) ? dump.reqPermissionStates : [];
if (names.length !== states.length) {
  fail(`bm dump lists ${names.length} permissions but ${states.length} states`);
}

let missing = 0;
const expected = aclPath ? JSON.parse(fs.readFileSync(aclPath, "utf8")).module?.requestPermissions ?? [] : [];
for (const { name } of expected) {
  if (!names.includes(name)) {
    console.log(`missing-variant ${name}`);
    missing += 1;
  }
}

let granted = 0;
let pending = 0;
for (const [index, name] of names.entries()) {
  const state = states[index];
  const mode = modes.get(name) ?? "unknown";
  if (mode === "user_grant") {
    // Granted by the user at runtime (or still to be granted): not our failure.
    console.log(`pending ${name} user_grant state=${state}`);
    pending += 1;
  } else if (state === 0) {
    console.log(`granted ${name} ${mode}`);
    granted += 1;
  } else {
    console.log(`missing ${name} ${mode} state=${state}`);
    missing += 1;
  }
}

console.log(`permissions: ${granted} granted, ${pending} user_grant, ${missing} missing`);
process.exit(missing === 0 ? 0 : 1);
