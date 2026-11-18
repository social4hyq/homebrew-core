"use strict";
const { test } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const AdmZip = require("node:module").createRequire(process.env.DEVECO_CLI_JS)("adm-zip");
const script = process.env.HAP_INSTALLER_SCRIPT || path.join(__dirname, "app-installer.sh");
const bundle = "com.example.desktop";
const basic = [{ name: "ohos.permission.INTERNET" }];
const acl = [...basic, { name: "ohos.permission.CUSTOM_SANDBOX", reason: "$string:reason", usedScene: { abilities: ["EntryAbility"], when: "inuse" } }];
function fixture(t) {
  const root = fs.mkdtempSync(path.join(process.env.TMPDIR || os.tmpdir(), "hap-test-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const bin = path.join(root, "bin");
  fs.mkdirSync(bin);
  const log = path.join(root, "calls.jsonl");
  const tool = (name, code) => {
    const file = path.join(bin, name);
    fs.writeFileSync(file, `#!${process.execPath}\n${code}\n`);
    fs.chmodSync(file, 0o755);
    return file;
  };
  const prelude = `const fs = require('node:fs'); const path = require('node:path'); const args = process.argv.slice(2); fs.appendFileSync(process.env.TEST_LOG, JSON.stringify([path.basename(process.argv[1]), ...args]) + '\\n');`;
  tool("devecocli", prelude + `
    if (process.env.EXTERNAL === '1') process.exit(99);
    if (args[0] === 'create') {
      const root = args[args.indexOf('--project-path') + 1];
      fs.mkdirSync(root + '/entry/src/main', {recursive:true});
      fs.mkdirSync(root + '/AppScope');
      fs.writeFileSync(root + '/AppScope/app.json5', '{}');
      fs.writeFileSync(root + '/build-profile.json5', '{}');
      fs.writeFileSync(root + '/entry/src/main/module.json5', '{// comment\\n module: {name:"entry", type:"entry", requestPermissions:[{name:"old"}],},}');
    }
    if (args[0] === 'signature') {
      const p = JSON.parse(fs.readFileSync('entry/src/main/module.json5', 'utf8'));
      fs.writeFileSync(process.env.TEST_PERMISSIONS, JSON.stringify(p.module.requestPermissions));
    }
  `);
  const hdc = tool("hdc", prelude + `
    if (args[0] === 'list') console.log(process.env.RECONNECT && fs.existsSync(process.env.HOME + '/connected') ? 'local TCP Connected localhost hdc' : (process.env.TEST_TARGETS || 'local TCP Connected localhost hdc'));
    if (args[0] === 'tconn') { fs.writeFileSync(process.env.HOME + '/connected', ''); console.log('connected'); }
    if (args.includes('shell')) {
      const cmd = args.slice(args.indexOf('shell') + 1).join(' ');
      if (cmd.includes('bm install')) { console.log(process.env.INSTALL_FAIL ? 'error: failed' : 'install bundle successfully'); }
      if (cmd.includes('aa start')) { console.log(process.env.START_FAIL ? 'screen locked' : 'start ability successfully'); }
    }
  `);
  tool("param", `console.log('45678');`);
  const signer = tool("signer", prelude + `fs.copyFileSync(args[args.indexOf('--hap')+1], args[args.indexOf('--output')+1]);`);
  const hap = path.join(root, "input.hap");
  function manifest(permissions, id = bundle) {
    const zip = new AdmZip();
    zip.addFile("module.json", Buffer.from(JSON.stringify({app:{bundleName:id}, module:{name:'electron', requestPermissions:permissions}})));
    zip.writeZip(hap);
  }
  manifest(acl);
  const env = {...process.env, HOME:root, TMPDIR:root, PATH:bin+':'+process.env.PATH,
    TEST_LOG:log, TEST_PERMISSIONS:path.join(root,'permissions.json'), HAP_INSTALLER_SIGNER:signer,
    HAP_SIGN_TOOL:signer, HAP_INSTALLER_PREPARE:path.join(__dirname,'prepare-profile.cjs')};
  function run(extra = [], overrides = {}) {
    return spawnSync('bash', [script, '--hap', hap, '--bundle-id', bundle, '--module', 'electron', ...extra], {env:{...env,...overrides}, encoding:'utf8'});
  }
  const calls = () => fs.existsSync(log) ? fs.readFileSync(log,'utf8').trim().split('\n').map(JSON.parse) : [];
  return {root, hap, hdc, manifest, run, calls, env};
}
test('automatic profiles replace permissions from the final HAP, including ACL to basic', t => {
  const f=fixture(t);
  for (const permissions of [acl,basic]) {
    f.manifest(permissions);
    const r=f.run(); assert.equal(r.status,0,r.stdout+r.stderr);
    assert.deepEqual(JSON.parse(fs.readFileSync(f.env.TEST_PERMISSIONS)),permissions.map(p => ({name:p.name})));
  }
});
test('external profile bypasses all DevEco account and project operations', t => {
  const f=fixture(t); const profile=path.join(f.root,'external.json5'); fs.writeFileSync(profile,'{}');
  const r=f.run(['--profile',profile],{EXTERNAL:'1'}); assert.equal(r.status,0,r.stdout+r.stderr);
  assert.ok(!f.calls().some(c=>c[0]==='devecocli'));
  assert.equal(fs.readFileSync(profile,'utf8'),'{}');
});
test('bundle mismatch fails before login or upload', t => {
  const f=fixture(t); f.manifest(basic,'com.example.wrong');
  const r=f.run(); assert.notEqual(r.status,0); assert.match(r.stderr,/bundle/i);
  assert.ok(!f.calls().some(c=>c[0]==='devecocli'||c.includes('send')));
});
test('explicit HDC and target are used for every transfer and cleanup', t => {
  const f=fixture(t); const r=f.run(['--hdc',f.hdc,'--device','chosen']); assert.equal(r.status,0,r.stdout+r.stderr);
  const operations=f.calls().filter(c=>c[0]==='hdc'&&c[1]!=='list');
  assert.ok(operations.length>0); assert.ok(operations.every(c=>c[1]==='-t'&&c[2]==='chosen'));
  assert.match(operations.at(-1).join(' '),/rm -f.*\.hap/);
});
test('failed installation still cleans remote files and never starts the app', t => {
  const f=fixture(t); const r=f.run([],{INSTALL_FAIL:'1'}); assert.notEqual(r.status,0);
  const calls=f.calls().map(c=>c.join(' '));
  assert.ok(!calls.some(c=>c.includes('aa start'))); assert.match(calls.at(-1),/rm -f.*\.hap/);
});
test('multiple connected targets require selection before login', t => {
  const f=fixture(t); const r=f.run([],{TEST_TARGETS:'one TCP Connected localhost hdc\ntwo USB Connected device hdc'});
  assert.equal(r.status,2); assert.match(r.stderr,/--device/);
  assert.ok(!f.calls().some(c=>c[0]==='devecocli'));
});

test('offline targets are reconnected using the current local port', t => {
  const f=fixture(t); const r=f.run([],{TEST_TARGETS:'local TCP Offline localhost hdc',RECONNECT:'1'});
  assert.equal(r.status,0,r.stdout+r.stderr);
  assert.ok(f.calls().some(c=>c[1]==='tconn'&&c[2]==='127.0.0.1:45678'));
});
test('an offline target never reaches login or upload', t => {
  const f=fixture(t); const r=f.run([],{TEST_TARGETS:'local TCP Offline localhost hdc'});
  assert.notEqual(r.status,0); assert.match(r.stderr,/no connected/);
  assert.ok(!f.calls().some(c=>c[0]==='devecocli'||c.includes('send')));
});
test('--no-start installs without launching', t => {
  const f=fixture(t); const r=f.run(['--no-start']); assert.equal(r.status,0,r.stdout+r.stderr);
  assert.ok(!f.calls().some(c=>c.join(' ').includes('aa start')));
});
test('unconfirmed app startup warns without failing installation', t => {
  const f=fixture(t); const r=f.run([],{START_FAIL:'1'}); assert.equal(r.status,0,r.stdout+r.stderr);
  assert.match(r.stderr,/start was not confirmed/);
});
test('missing external profile fails without account operations', t => {
  const f=fixture(t); const r=f.run(['--profile',path.join(f.root,'missing')],{EXTERNAL:'1'});
  assert.notEqual(r.status,0); assert.match(r.stderr,/profile not found/);
  assert.ok(!f.calls().some(c=>c[0]==='devecocli'));
});

test('signed output cannot overwrite the input HAP', t => {
  const f=fixture(t); const before=fs.readFileSync(f.hap);
  const r=f.run(['--signed-hap',f.hap]); assert.notEqual(r.status,0);
  assert.deepEqual(fs.readFileSync(f.hap),before);
});
