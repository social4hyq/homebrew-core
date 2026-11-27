#!/usr/bin/env node
"use strict";
// Dual-backend contract tests with fake hdc. No real device, no sideload API.
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");
const crypto = require("node:crypto");
const { spawnSync } = require("node:child_process");

const CLI = path.join(__dirname, "ohos-device.cjs");
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "ohos-device-test-"));
let passed = 0, failed = 0;
function test(name, fn) {
  try { fn(); passed += 1; console.log("PASS", name); }
  catch (e) { failed += 1; console.error("FAIL", name, "-", e.message); }
}
function fakeHdc(scenario) {
  const p = path.join(tmp, `fake-hdc-${scenario}.sh`);
  fs.writeFileSync(p, `#!/usr/bin/env bash
logf="\${FAKE_HDC_LOG:-/dev/null}"
printf '%s\\n' "$*" >> "$logf"
# strip leading "-t <device>" so case matching works regardless of target
args=("$@")
if [ "\${args[0]}" = "-t" ]; then args=("\${args[@]:2}"); fi
set -- "\${args[@]}"
case "$1 $2" in
  "list targets") echo "tablet-1" ;;
  "file send") exit 0 ;;
  "shell bm")
    case "$3" in
      install) echo "bm install success" ;;
      dump) echo '{"app":{"bundleName":"com.example.app","versionCode":42,"versionName":"1.0"},"reqPermissionStates":[]}' ;;
      uninstall) echo "uninstall bundle successfully" ;;
    esac
    exit 0 ;;
  "shell aa") echo "aa ok"; exit 0 ;;
  "shell ps") echo "u 1 1 com.example.app"; exit 0 ;;
  "shell hilog") echo "log line"; exit 0 ;;
esac
exit 0
`);
  fs.chmodSync(p, 0o755);
  return p;
}
function makeSignedHap() {
  const p = path.join(tmp, "signed.hap");
  fs.writeFileSync(p, Buffer.concat([Buffer.from([0x50, 0x4b, 3, 4]), Buffer.alloc(200, 7)]));
  return p;
}
function run(args, hdc) {
  return spawnSync(process.execPath, [CLI, ...args], {
    encoding: "utf8", env: { ...process.env, HDC: hdc, FAKE_HDC_LOG: path.join(tmp, "hdc.log") },
  });
}
function events(res) {
  return (res.stdout || "").trim().split("\n").filter(Boolean).map((l) => JSON.parse(l));
}
function req(over = {}) {
  const hap = makeSignedHap();
  return { protocol_version: 1, method: "hdc", device: "tablet-1", hap_path: hap,
    hap_sha256: crypto.createHash("sha256").update(fs.readFileSync(hap)).digest("hex"),
    expected: { bundle_id: "com.example.app", version_code: 42 }, wait: true, ...over };
}
function writeReq(r, name) {
  const p = path.join(tmp, name || "req.json"); fs.writeFileSync(p, JSON.stringify(r)); return p;
}

const hdc = fakeHdc("ok");

test("backends list: hdc available, sideload unavailable (fail-closed)", () => {
  const res = run(["backends", "list"], hdc);
  assert.equal(res.status, 0, res.stderr);
  const bs = events(res)[0].backends;
  const hdcB = bs.find((b) => b.backend === "hdc");
  const slB = bs.find((b) => b.backend === "sideload");
  assert.equal(hdcB.available, true);
  assert.equal(slB.available, false);
  assert.match(slB.unavailable_reason, /not published/);
});

test("hdc backend: install emits installing->installed with post verification", () => {
  const rf = writeReq(req());
  const res = run(["install", "--request", rf], hdc);
  assert.equal(res.status, 0, res.stderr);
  const ev = events(res);
  assert.equal(ev[0].type, "install_state");
  assert.equal(ev[0].state, "installing");
  const last = ev[ev.length - 1];
  assert.equal(last.type, "install_result");
  assert.equal(last.state, "installed");
  assert.equal(last.verification.bundle_matched, true);
  assert.equal(last.verification.version_matched, true);
  assert.ok(last.verification.unsupported.includes("certificate_verify"));
});

test("explicit sideload: fail closed BEFORE any hdc call", () => {
  fs.writeFileSync(path.join(tmp, "hdc.log"), "");
  const rf = writeReq(req({ method: "sideload" }), "req-sl.json");
  const res = run(["install", "--request", rf], hdc);
  assert.notEqual(res.status, 0);
  assert.match(res.stdout, /ERR_BACKEND_UNAVAILABLE/);
  assert.equal(fs.readFileSync(path.join(tmp, "hdc.log"), "utf8").trim(), "", "no hdc call allowed");
});

test("no pending file created on failure", () => {
  const rf = writeReq(req({ method: "sideload" }), "req-failcase.json"); // 名字勿含 "pending"
  const before = fs.readdirSync(tmp).filter((f) => f.startsWith("pending")).length;
  run(["install", "--request", rf], hdc);
  const after = fs.readdirSync(tmp).filter((f) => f.startsWith("pending")).length;
  assert.equal(after, before);
});

test("install-status: unsupported, no fabricated ID", () => {
  const res = run(["install-status", "--operation-id", "fake-op"], hdc);
  assert.notEqual(res.status, 0);
  assert.match(res.stdout, /ERR_STATUS_QUERY_UNSUPPORTED/);
});

test("uninstall: default keeps data (-k), --purge omits it", () => {
  fs.writeFileSync(path.join(tmp, "hdc.log"), "");
  let res = run(["uninstall", "--bundle-id", "com.example.app"], hdc);
  assert.equal(res.status, 0, res.stderr);
  let log = fs.readFileSync(path.join(tmp, "hdc.log"), "utf8");
  assert.match(log, /bm uninstall -n com\.example\.app -k/);
  fs.writeFileSync(path.join(tmp, "hdc.log"), "");
  res = run(["uninstall", "--bundle-id", "com.example.app", "--purge"], hdc);
  assert.equal(res.status, 0, res.stderr);
  log = fs.readFileSync(path.join(tmp, "hdc.log"), "utf8");
  assert.match(log, /bm uninstall -n com\.example\.app$/m);
});

test("start/stop/status: only device lifecycle, no sign or download", () => {
  fs.writeFileSync(path.join(tmp, "hdc.log"), "");
  let res = run(["start", "--bundle-id", "com.example.app", "--module", "entry", "--ability", "EntryAbility"], hdc);
  assert.equal(res.status, 0, res.stderr);
  res = run(["status", "--bundle-id", "com.example.app"], hdc);
  assert.equal(res.status, 0, res.stderr);
  assert.equal(events(res)[0].running, true);
  const log = fs.readFileSync(path.join(tmp, "hdc.log"), "utf8");
  assert.match(log, /aa start/);
  assert.doesNotMatch(log, /sign|download|keystore/i);
});

test("wrong protocol_version fails closed", () => {
  const rf = writeReq(req({ protocol_version: 9 }), "req-badver.json");
  const res = run(["install", "--request", rf], hdc);
  assert.notEqual(res.status, 0);
  assert.match(res.stdout, /ERR_UNSUPPORTED_PROTOCOL/);
});

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
