"use strict";

const { test } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

const decoder = require(path.join(__dirname, "deveco-decoder.cjs"));
const signer = path.join(__dirname, "sign-hap.cjs");
const renamed = [
  { cls: "Rs", path: "W", crypto: "Um", fs: "we", log: "m" },
  { cls: "Os", path: "V", crypto: "Jm", fs: "ye", log: "m" },
  { cls: "Zq", path: "a$", crypto: "Kb", fs: "Lc", log: "dbg" },
];

function decoderSource(n) {
  return `import"x";var ${n.cls}=class n{static decryptPwd(e,t,r){${n.log}(\`[DecipherUtil] \${r}\`);` +
    `return ${n.path}.resolve(e,"material")+"|"+${n.fs}.statSync("/").isDirectory()+"|"+` +
    `${n.crypto}.pbkdf2Sync("p","s",1,4,"sha256").length+"|"+r}};export{n as x};`;
}

function cliFixture(t, source) {
  const root = fs.mkdtempSync(path.join(process.env.TMPDIR || os.tmpdir(), "deveco-decoder-test-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  fs.mkdirSync(path.join(root, "dist"));
  const cli = path.join(root, "dist", "cli.js");
  fs.writeFileSync(cli, source);
  fs.writeFileSync(path.join(root, "package.json"), JSON.stringify({ version: "1.3.12" }));
  return cli;
}

test("the decoder adapter follows minified class and alias names", t => {
  for (const names of renamed) {
    const cli = cliFixture(t, decoderSource(names));
    assert.deepEqual(decoder.checkDecoder(cli), { cli, version: "1.3.12" }, names.cls);
    const passwords = decoder.decodePasswords(cli, "/cfg", "store", "key");
    assert.deepEqual(passwords, {
      storePassword: "/cfg/material|true|4|storePassword",
      keyPassword: "/cfg/material|true|4|keyPassword",
    }, names.cls);
  }
});

test("the decoder adapter refuses layouts it cannot identify", t => {
  let cli = cliFixture(t, "var a=class n{};");
  assert.throws(() => decoder.checkDecoder(cli), /decoder is missing/);
  cli = cliFixture(t, "var a=class n{};var b={};static decryptPwd(");
  assert.throws(() => decoder.checkDecoder(cli), /does not contain decryptPwd/);
  cli = cliFixture(t, "var a=class n{static decryptPwd(e){m(`[DecipherUtil]`);return A.resolve(e)+B.join(e)+C.pbkdf2Sync()+D.statSync()}}");
  assert.throws(() => decoder.checkDecoder(cli), /path alias is ambiguous/);
});

test("the shipped DevEco CLI passes the decoder preflight", { skip: !process.env.DEVECO_CLI_JS }, () => {
  const result = decoder.checkDecoder(process.env.DEVECO_CLI_JS);
  assert.equal(result.cli, process.env.DEVECO_CLI_JS);
  assert.match(result.version, /^\d+\.\d+\.\d+/);
  assert.throws(() => decoder.decodePasswords(
    process.env.DEVECO_CLI_JS, "/nonexistent-deveco-config", "ab".repeat(20), "ab".repeat(20)),
  { code: "ENOENT" });
});

test("the signer preflight needs neither a HAP nor signing passwords", { skip: !process.env.DEVECO_CLI_JS }, () => {
  const result = spawnSync(process.execPath,
    [signer, "--check-decoder", "--cli", process.env.DEVECO_CLI_JS], { encoding: "utf8" });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(result.stdout, /DevEco CLI decoder compatible/);
  const packageJson = JSON.parse(fs.readFileSync(
    path.join(path.dirname(process.env.DEVECO_CLI_JS), "../package.json"), "utf8"));
  assert.match(result.stdout, new RegExp(packageJson.version.replaceAll(".", "\\.")));
});

test("the signer preflight reports incompatibility without a stack trace", t => {
  const cli = cliFixture(t, "var a=class n{};");
  const result = spawnSync(process.execPath, [signer, "--check-decoder", "--cli", cli], { encoding: "utf8" });
  assert.equal(result.status, 1);
  assert.match(result.stderr, /decoder is missing/);
  assert.doesNotMatch(result.stderr, /\n\s+at /);
});
