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
    `fs.appendFileSync(process.env.TEST_LOG, JSON.stringify([process.env.HAP_APP_TEST_NAME||path.basename(process.argv[1]),...args,{noStart:process.env.HAP_INSTALLER_NO_START||'',noLogin:process.env.HAP_INSTALLER_NO_LOGIN||'',device:process.env.HAP_INSTALLER_DEVICE||'',httpsProxy:process.env.HTTPS_PROXY||'',noProxy:process.env.NO_PROXY||'',tlsInsecure:process.env.HAP_INSTALLER_TLS_INSECURE||''}])+'\\n');`;
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
    if (args[0] === 'install') {
      if (process.env.APP_FAIL_REASON && process.env.HAP_INSTALLER_RESULT_FILE) {
        fs.writeFileSync(process.env.HAP_INSTALLER_RESULT_FILE,
          JSON.stringify({ v: 1, reason: process.env.APP_FAIL_REASON, detail: process.env.APP_FAIL_DETAIL || '' }) + String.fromCharCode(10));
      }
      if (process.env.APP_LOG_LINE) console.log(process.env.APP_LOG_LINE);
      process.exit(process.env.APP_INSTALL_FAIL ? 1 : 0);
    }
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
    HOMEBREW_PREFIX: path.join(root, ".harmonybrew"),
    HAP_APP_USER_HOME: "",
    CI: "",
    GITHUB_ACTIONS: "",
    HOMEBREW_GITHUB_ACTIONS: "",
    HAP_APP_AUTO_LOGIN: "",
    HTTPS_PROXY: "",
    https_proxy: "",
    HTTP_PROXY: "",
    http_proxy: "",
    NO_PROXY: "",
    no_proxy: "",
  };
  function run(args, overrides = {}) {
    return spawnSync("bash", [script, ...args], { env: { ...env, ...overrides }, encoding: "utf8" });
  }
  const calls = () => fs.existsSync(log)
    ? fs.readFileSync(log, "utf8").trim().split("\n").filter(Boolean).map(JSON.parse)
    : [];
  const queueDir = path.join(root, ".cache", "hap-app", "pending");
  const configDir = path.join(root, ".config", "hap-app");
  const queued = () => fs.existsSync(queueDir) ? fs.readdirSync(queueDir).sort() : [];
  const queuedEntry = name => JSON.parse(fs.readFileSync(path.join(queueDir, `${name}.json`), "utf8"));
  return { root, bin, acl, env, run, calls, queued, queuedEntry, configDir };
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
  assert.ok(!f.calls().some(c => c[0] === "app-installer" && c[1] === "login"),
    "an existing login must not start another login");
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

test('a missing login opens the browser once by default and then installs', t => {
  const f = fixture(t);
  const r = f.run(["auto-install", "orca-app", "com.example.desktop"],
    { READY_BEFORE: "no-login", READY_AFTER: "ok local" });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.match(r.stdout, /已装机/);
  assert.equal(f.calls().filter(c => c[0] === "app-installer" && c[1] === "login").length, 1);
  assert.deepEqual(f.queued(), []);
});

test('HAP_APP_AUTO_LOGIN=0 queues without opening the browser', t => {
  const f = fixture(t);
  const r = f.run(["auto-install", "orca-app", "com.example.desktop"],
    { READY: "no-login", HAP_APP_AUTO_LOGIN: "0" });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.match(r.stdout, /未登录华为开发者/);
  assert.equal(f.queuedEntry("orca-app").reason, "login");
  assert.ok(!f.calls().some(c => c[0] === "app-installer" && c[1] === "login"));
});

test('auto_login=0 in the config file disables the browser login', t => {
  const f = fixture(t);
  fs.mkdirSync(f.configDir, { recursive: true });
  fs.writeFileSync(path.join(f.configDir, "config"), "auto_login=0\n");
  const r = f.run(["auto-install", "orca-app", "com.example.desktop"], { READY: "no-login" });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.equal(f.queuedEntry("orca-app").reason, "login");
  assert.ok(!f.calls().some(c => c[0] === "app-installer" && c[1] === "login"));
});

test('an incomplete login is queued and not retried for the next app', t => {
  const f = fixture(t);
  const options = { READY: "no-login", LOGIN_FAIL: "1" };
  const first = f.run(["auto-install", "orca-app", "com.example.desktop"], options);
  assert.equal(first.status, 0, first.stdout + first.stderr);
  assert.equal(f.queuedEntry("orca-app").reason, "login");
  const second = f.run(["auto-install", "zcode-app", "com.example.zcode"], options);
  assert.equal(second.status, 0, second.stdout + second.stderr);
  assert.equal(f.queuedEntry("zcode-app").reason, "login");
  assert.equal(f.calls().filter(c => c[0] === "app-installer" && c[1] === "login").length, 1);
});

test('an install failure queues the app and keeps brew install successful', t => {
  const f = fixture(t);
  const r = f.run(["auto-install", "orca-app", "com.example.desktop"], { APP_INSTALL_FAIL: "1" });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.match(r.stdout, /装机失败：安装失败（已登记，共 1 个待装）/);
  assert.match(r.stdout, /→ 查看日志或运行 hap-app status/);
  assert.match(r.stdout, /日志：.*logs\/.*-orca-app\.log/);
  assert.equal(f.queuedEntry("orca-app").reason, "install-failed");
});

test('a structured failure reason drives the queue entry and the hint', t => {
  const f = fixture(t);
  const r = f.run(["auto-install", "orca-app", "com.example.desktop"],
    { APP_INSTALL_FAIL: "1", APP_FAIL_REASON: "tls" });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.match(r.stdout, /TLS 证书链不受信/);
  assert.match(r.stdout, /tls_ca=\/path\/to\/ca\.pem/);
  assert.equal(f.queuedEntry("orca-app").reason, "tls");
});

test('the default automatic path prints one start line and one result line', t => {
  const f = fixture(t);
  const r = f.run(["auto-install", "orca-app", "com.example.desktop"]);
  assert.equal(r.status, 0, r.stdout + r.stderr);
  const lines = (r.stdout + r.stderr).split("\n").filter(Boolean);
  assert.equal(lines.length, 2, r.stdout + r.stderr);
  assert.ok(lines.some(line => /installing orca-app/.test(line)), r.stdout + r.stderr);
  assert.ok(lines.some(line => /已装机 com\.example\.desktop（设备 local）/.test(line)), r.stdout + r.stderr);
  const logs = fs.readdirSync(path.join(f.root, ".cache", "hap-app", "logs"));
  assert.equal(logs.filter(name => name.endsWith("-orca-app.log")).length, 1);
});

test('verbose streams the app output and keeps it in the log', t => {
  const f = fixture(t);
  fs.mkdirSync(f.configDir, { recursive: true });
  fs.writeFileSync(path.join(f.configDir, "config"), "verbose=1\n");
  const r = f.run(["auto-install", "orca-app", "com.example.desktop"],
    { APP_LOG_LINE: "chatty install detail" });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.match(r.stderr, /chatty install detail/);
  const logDir = path.join(f.root, ".cache", "hap-app", "logs");
  const log = fs.readdirSync(logDir).find(name => name.endsWith("-orca-app.log"));
  assert.match(fs.readFileSync(path.join(logDir, log), "utf8"), /chatty install detail/);
});

test('hap-app login delegates to app-installer login', t => {
  const f = fixture(t);
  const r = f.run(["login", "--timeout", "5"]);
  assert.equal(r.status, 0, r.stdout + r.stderr);
  const login = f.calls().find(c => c[0] === "app-installer" && c[1] === "login");
  assert.ok(login, "login must be delegated");
  assert.deepEqual(login.slice(2, 4), ["--timeout", "5"]);
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
  assert.match(r.stdout, /已装机 com\.example\.desktop（设备 local）/);
  assert.match(r.stdout, /补装完成：1 个成功/);
  assert.deepEqual(f.queued(), []);
});

test('status lists the queue and forget removes one entry', t => {
  const f = fixture(t);
  assert.equal(f.run(["auto-install", "orca-app", "com.example.desktop"], { READY: "no-device" }).status, 0);
  let r = f.run(["status"]);
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.match(r.stdout, /待装 1 个/);
  assert.match(r.stdout, /orca-app\s+com\.example\.desktop\s+device/);
  assert.match(r.stdout, /连接并解锁设备后运行 hap-app install-pending/);
  assert.match(r.stdout, /日志：.*\.cache\/hap-app\/logs/);
  r = f.run(["status", "--tsv"]);
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.match(r.stdout, /^orca-app\tcom\.example\.desktop\tdevice\t/m);
  r = f.run(["forget", "orca-app"]);
  assert.equal(r.status, 0);
  assert.deepEqual(f.queued(), []);
});

test('recovers the real home from HOMEBREW_PREFIX when brew isolates HOME', t => {
  const f = fixture(t);
  const isolated = path.join(f.root, "herdr-postinstall-isolated");
  fs.mkdirSync(isolated);
  fs.mkdirSync(path.join(f.root, ".harmony"));
  const r = f.run(["auto-install", "orca-app", "com.example.desktop"], {
    HOME: isolated,
    HOMEBREW_PREFIX: path.join(f.root, ".harmonybrew"),
  });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.match(r.stdout, /已装机/);
  assert.deepEqual(f.queued(), [], "the queue must use the recovered home");
});

test('postinstall app installs inherit https_proxy from the recovered home', t => {
  const f = fixture(t);
  const isolated = path.join(f.root, "proxy-postinstall-isolated");
  fs.mkdirSync(isolated);
  fs.mkdirSync(path.join(f.root, ".app-installer"), { recursive: true });
  fs.writeFileSync(path.join(f.root, ".app-installer/config"),
    "https_proxy=http://127.0.0.1:7890\nno_proxy=localhost,127.0.0.1,.internal\ntls_insecure=1\n");
  const r = f.run(["auto-install", "orca-app", "com.example.desktop"], {
    HOME: isolated,
    HOMEBREW_PREFIX: path.join(f.root, ".harmonybrew"),
  });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  const install = f.calls().find(c => c[0] === "orca-app");
  assert.equal(install[2].httpsProxy, "http://127.0.0.1:7890");
  assert.equal(install[2].noProxy, "localhost,127.0.0.1,.internal");
  assert.equal(install[2].tlsInsecure, "1");
});

test('a proxy already present in the shell takes precedence over the config file', t => {
  const f = fixture(t);
  fs.mkdirSync(path.join(f.root, ".app-installer"), { recursive: true });
  fs.writeFileSync(path.join(f.root, ".app-installer/config"),
    "https_proxy=http://127.0.0.1:7890\nno_proxy=localhost,127.0.0.1,.internal\ntls_insecure=1\n");
  const r = f.run(["auto-install", "orca-app", "com.example.desktop"], {
    HTTPS_PROXY: "http://127.0.0.1:9999",
  });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  const install = f.calls().find(c => c[0] === "orca-app");
  assert.equal(install[2].httpsProxy, "http://127.0.0.1:9999");
  assert.equal(install[2].noProxy, "localhost,127.0.0.1,.internal",
    "a shell HTTPS_PROXY must not suppress the configured no_proxy");
});

test('NO_PROXY already present in the shell takes precedence over the config file', t => {
  const f = fixture(t);
  fs.mkdirSync(path.join(f.root, ".app-installer"), { recursive: true });
  fs.writeFileSync(path.join(f.root, ".app-installer/config"), "no_proxy=config.internal\ntls_insecure=1\n");
  const r = f.run(["auto-install", "orca-app", "com.example.desktop"], {
    NO_PROXY: "shell.internal",
    HAP_INSTALLER_TLS_INSECURE: "0",
  });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  const install = f.calls().find(c => c[0] === "orca-app");
  assert.equal(install[2].noProxy, "shell.internal");
  assert.equal(install[2].tlsInsecure, "0");
});

test('the config file can switch automatic installs off', t => {
  const f = fixture(t);
  fs.mkdirSync(f.configDir, { recursive: true });
  fs.writeFileSync(path.join(f.configDir, "config"), "auto_install=0\n");
  const r = f.run(["auto-install", "orca-app", "com.example.desktop"]);
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.match(r.stderr, /自动装机已关闭/);
  assert.deepEqual(f.calls(), []);
  assert.deepEqual(f.queued(), []);
});

test('a clean PC without marker files still gets the queue in the real home', t => {
  const f = fixture(t);
  const isolated = path.join(f.root, "fresh-postinstall");
  fs.mkdirSync(isolated);
  fs.mkdirSync(path.join(f.root, ".harmonybrew"));
  const r = f.run(["auto-install", "orca-app", "com.example.desktop"], {
    HOME: isolated,
    HOMEBREW_PREFIX: path.join(f.root, ".harmonybrew"),
    READY: "no-device",
  });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.deepEqual(f.queued(), ["orca-app.json"], "the queue must use the recovered home");
});

test('an unresolved TLS failure short-circuits the next automatic attempt', t => {
  const f = fixture(t);
  const first = f.run(["auto-install", "orca-app", "com.example.desktop"],
    { APP_INSTALL_FAIL: "1", APP_FAIL_REASON: "tls" });
  assert.equal(first.status, 0, first.stdout + first.stderr);
  assert.equal(f.queuedEntry("orca-app").reason, "tls");
  const second = f.run(["auto-install", "zcode-app", "com.example.zcode"]);
  assert.equal(second.status, 0, second.stdout + second.stderr);
  assert.match(second.stdout, /未重复尝试/);
  assert.equal(f.queuedEntry("zcode-app").reason, "tls");
  assert.ok(!f.calls().some(c => c[0] === "zcode-app" && c[1] === "install"),
    "the skipped attempt must not call the app installer");
});

test('changing the network config re-enables the automatic attempt', t => {
  const f = fixture(t);
  assert.equal(f.run(["auto-install", "orca-app", "com.example.desktop"],
    { APP_INSTALL_FAIL: "1", APP_FAIL_REASON: "tls" }).status, 0);
  fs.mkdirSync(path.join(f.root, ".app-installer"), { recursive: true });
  fs.writeFileSync(path.join(f.root, ".app-installer", "config"), "tls_ca=/tmp/fixed.pem\n");
  const r = f.run(["auto-install", "zcode-app", "com.example.zcode"]);
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.ok(f.calls().some(c => c[0] === "zcode-app" && c[1] === "install"));
  assert.deepEqual(f.queued(), ["orca-app.json"]);
});

test('install-pending clears the TLS short-circuit marker', t => {
  const f = fixture(t);
  assert.equal(f.run(["auto-install", "orca-app", "com.example.desktop"],
    { APP_INSTALL_FAIL: "1", APP_FAIL_REASON: "tls" }).status, 0);
  const marker = path.join(f.root, ".cache", "hap-app", "tls-blocked");
  assert.ok(fs.existsSync(marker), "the failure must leave a marker");
  assert.equal(f.run(["install-pending"]).status, 0);
  assert.ok(!fs.existsSync(marker), "a manual retry must clear the marker");
});

test('queue entries keep the failure detail and the attempt count', t => {
  const f = fixture(t);
  assert.equal(f.run(["auto-install", "orca-app", "com.example.desktop"],
    { APP_INSTALL_FAIL: "1", APP_FAIL_REASON: "tls", APP_FAIL_DETAIL: "certificate chain" }).status, 0);
  let entry = f.queuedEntry("orca-app");
  assert.equal(entry.detail, "certificate chain");
  assert.equal(entry.attempts, 1);
  fs.rmSync(path.join(f.root, ".cache", "hap-app", "tls-blocked"));
  assert.equal(f.run(["auto-install", "orca-app", "com.example.desktop"],
    { APP_INSTALL_FAIL: "1", APP_FAIL_REASON: "tls", APP_FAIL_DETAIL: "certificate chain" }).status, 0);
  entry = f.queuedEntry("orca-app");
  assert.equal(entry.attempts, 2);
  const r = f.run(["status"]);
  assert.match(r.stdout, /最近失败：certificate chain/);
});

test('a broken queue entry is kept and reported for forget', t => {
  const f = fixture(t);
  const dir = path.join(f.root, ".cache", "hap-app", "pending");
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, "bad.json"), "{not json");
  const r = f.run(["install-pending"]);
  assert.notEqual(r.status, 0, r.stdout + r.stderr);
  assert.match(r.stderr, /队列条目损坏：bad/);
  assert.deepEqual(f.queued(), ["bad.json"], "the broken entry must stay for inspection");
});
