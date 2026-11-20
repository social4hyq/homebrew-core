"use strict";
const { test } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const script = path.join(__dirname, "hap-app.sh");

function fixture(t) {
  const root = fs.mkdtempSync(path.join(process.env.TMPDIR || os.tmpdir(), "hap-app-test-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const bin = path.join(root, "bin");
  fs.mkdirSync(bin);
  const log = path.join(root, "calls.jsonl");
  const prelude = `const fs=require('node:fs');const path=require('node:path');const args=process.argv.slice(2);` +
    `fs.appendFileSync(process.env.TEST_LOG, JSON.stringify([process.env.HAP_APP_TEST_NAME||path.basename(process.argv[1]),...args,{noStart:process.env.HAP_INSTALLER_NO_START||'',noLogin:process.env.HAP_INSTALLER_NO_LOGIN||'',device:process.env.HAP_INSTALLER_DEVICE||''}])+'\\n');`;
  const tool = (name, code) => {
    const file = path.join(bin, name);
    fs.writeFileSync(file, `#!${process.execPath}\n${prelude}\n${code}\n`);
    fs.chmodSync(file, 0o755);
    return file;
  };

  tool("app-installer", `
    if (args[0] === 'ready') {
      const logged = fs.existsSync(process.env.HOME + '/fake-login');
      const out = logged ? (process.env.READY_AFTER || process.env.READY || 'ok local')
                         : (process.env.READY_BEFORE || process.env.READY || 'ok local');
      console.log(out);
      process.exit(out.startsWith('ok') ? 0 : 1);
    }
    if (args[0] === 'login') {
      fs.writeFileSync(process.env.HOME + '/fake-login', '');
      console.log('logged in');
      process.exit(process.env.LOGIN_FAIL ? 1 : 0);
    }
    if (args[0] === 'permissions') {
      console.log(process.env.PERMS_OUT || 'permissions: 1 granted, 0 user_grant, 0 missing');
      process.exit(process.env.PERMS_FAIL ? 1 : 0);
    }
    process.exit(0);
  `);

  tool("orca-app", `
    if (args[0] === 'install') process.exit(process.env.APP_INSTALL_FAIL ? 1 : 0);
    process.exit(0);
  `);

  // A wrapper shaped like brew's write_env_script output, exporting the ACL path.
  const acl = path.join(root, "module-acl.json");
  fs.writeFileSync(acl, JSON.stringify({ module: { requestPermissions: [{ name: "ohos.permission.INTERNET" }] } }));
  fs.writeFileSync(path.join(bin, "zcode-app"),
    `#!/bin/sh\nHAP_APP_TEST_NAME=zcode-app ZCODE_DESKTOP_MODULE_ACL="${acl}" exec "${bin}/orca-app" "$@"\n`);
  fs.chmodSync(path.join(bin, "zcode-app"), 0o755);

  const env = {
    ...process.env,
    HOME: root,
    TMPDIR: root,
    XDG_CONFIG_HOME: path.join(root, "config"),
    XDG_CACHE_HOME: path.join(root, "cache"),
    PATH: bin + ":" + process.env.PATH,
    TEST_LOG: log,
    HAP_APP_APP_INSTALLER: path.join(bin, "app-installer"),
    HAP_APP_NODE: process.execPath,
    HAP_APP_INSTALL_TIMEOUT: "60",
    HAP_APP_ALLOW_ROOT: "1",
    CI: "",
    GITHUB_ACTIONS: "",
    HOMEBREW_GITHUB_ACTIONS: "",
    HAP_APP_AUTO_LOGIN: "",
  };
  function run(args, overrides = {}) {
    return spawnSync("bash", [script, ...args], { env: { ...env, ...overrides }, encoding: "utf8" });
  }
  const calls = () => fs.existsSync(log)
    ? fs.readFileSync(log, "utf8").trim().split("\n").filter(Boolean).map(JSON.parse)
    : [];
  const queueDir = path.join(env.XDG_CONFIG_HOME, "hap-app", "pending");
  const queued = () => fs.existsSync(queueDir) ? fs.readdirSync(queueDir).sort() : [];
  const queuedEntry = name => JSON.parse(fs.readFileSync(path.join(queueDir, `${name}.json`), "utf8"));
  return { root, bin, acl, env, run, calls, queued, queuedEntry };
}

test('auto-install signs, installs and verifies permissions without starting the app', t => {
  const f = fixture(t);
  const r = f.run(["auto-install", "orca-app", "com.example.desktop"]);
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.match(r.stdout, /已装机 com\.example\.desktop（设备 local）/);
  const install = f.calls().find(c => c[0] === "orca-app");
  assert.ok(install, "the app install must run");
  assert.equal(install[2].noStart, "1", "the auto path must not start the app");
  assert.equal(install[2].noLogin, "1", "the auto path must not block on a login");
  const permissions = f.calls().find(c => c[0] === "app-installer" && c[1] === "permissions");
  assert.ok(permissions, "permissions must be checked after installing");
  assert.equal(permissions[2], "--bundle-id");
  assert.deepEqual(f.queued(), []);
});

test('a missing device queues the app instead of failing', t => {
  const f = fixture(t);
  const r = f.run(["auto-install", "orca-app", "com.example.desktop"], { READY: "no-device" });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.match(r.stdout, /设备未就绪（no-device）/);
  assert.deepEqual(f.queued(), ["orca-app.json"]);
  assert.equal(f.queuedEntry("orca-app").reason, "device");
  assert.ok(!f.calls().some(c => c[0] === "orca-app"));
});

test('a missing login queues the app without starting the browser by default', t => {
  const f = fixture(t);
  const r = f.run(["auto-install", "orca-app", "com.example.desktop"], { READY: "no-login" });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.match(r.stdout, /未登录华为开发者/);
  assert.equal(f.queuedEntry("orca-app").reason, "login");
  assert.ok(!f.calls().some(c => c[0] === "app-installer" && c[1] === "login"),
    "auto-install must not open the login unless HAP_APP_AUTO_LOGIN=1");
});

test('HAP_APP_AUTO_LOGIN=1 logs in once and then installs', t => {
  const f = fixture(t);
  const r = f.run(["auto-install", "orca-app", "com.example.desktop"],
    { READY_BEFORE: "no-login", READY_AFTER: "ok local", HAP_APP_AUTO_LOGIN: "1" });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.match(r.stdout, /已装机/);
  assert.ok(f.calls().some(c => c[0] === "app-installer" && c[1] === "login"));
  assert.deepEqual(f.queued(), []);
});

test('an install failure queues the app and keeps brew install successful', t => {
  const f = fixture(t);
  const r = f.run(["auto-install", "orca-app", "com.example.desktop"], { APP_INSTALL_FAIL: "1" });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.match(r.stdout, /装机失败（install-failed）/);
  assert.equal(f.queuedEntry("orca-app").reason, "install-failed");
});

test('a permission failure queues the app after it was installed', t => {
  const f = fixture(t);
  const r = f.run(["auto-install", "orca-app", "com.example.desktop"], { PERMS_FAIL: "1" });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.match(r.stdout, /权限校验未通过/);
  assert.equal(f.queuedEntry("orca-app").reason, "permissions");
});

test('an app wrapper with an ACL module gets --expect-acl', t => {
  const f = fixture(t);
  const r = f.run(["auto-install", "zcode-app", "com.example.zcode"]);
  assert.equal(r.status, 0, r.stdout + r.stderr);
  const permissions = f.calls().find(c => c[0] === "app-installer" && c[1] === "permissions");
  const index = permissions.indexOf("--expect-acl");
  assert.ok(index > 0, "--expect-acl must be passed for an ACL app");
  assert.equal(permissions[index + 1], f.acl);
});

test('CI never installs or queues anything', t => {
  const f = fixture(t);
  const r = f.run(["auto-install", "orca-app", "com.example.desktop"], { CI: "true" });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.deepEqual(f.calls(), []);
  assert.deepEqual(f.queued(), []);
});

test('--start passes the request through to the app install', t => {
  const f = fixture(t);
  const r = f.run(["auto-install", "orca-app", "com.example.desktop", "--start"]);
  assert.equal(r.status, 0, r.stdout + r.stderr);
  const install = f.calls().find(c => c[0] === "orca-app" && c[1] === "install");
  assert.equal(install[2].noStart, "");
  assert.ok(f.calls().some(c => c[0] === "orca-app" && c[1] === "start"));
});

test('install-pending installs the queued apps and empties the queue', t => {
  const f = fixture(t);
  assert.equal(f.run(["auto-install", "orca-app", "com.example.desktop"], { READY: "no-device" }).status, 0);
  assert.deepEqual(f.queued(), ["orca-app.json"]);
  const r = f.run(["install-pending"]);
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.match(r.stdout, /补装完成：1 个成功/);
  assert.deepEqual(f.queued(), []);
});

test('status lists the queue and forget removes one entry', t => {
  const f = fixture(t);
  assert.equal(f.run(["auto-install", "orca-app", "com.example.desktop"], { READY: "no-device" }).status, 0);
  let r = f.run(["status"]);
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.match(r.stdout, /^orca-app\tcom\.example\.desktop\tdevice\t/m);
  r = f.run(["forget", "orca-app"]);
  assert.equal(r.status, 0);
  assert.deepEqual(f.queued(), []);
});
