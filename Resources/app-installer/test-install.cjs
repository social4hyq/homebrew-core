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
    if (args[0] === 'auth' && args[1] === 'status' && process.env.NEED_LOGIN && !fs.existsSync(process.env.HOME + '/logged')) console.log('Not logged in');
    if (args[0] === 'auth' && args[1] === 'login') {
      console.log('无法自动打开浏览器，请手动复制以下登录链接到浏览器打开：');
      console.log('https://developer.huawei.com/consumer/cn/oauth?code=1&x=a%20b');
      console.log('Waiting for login...');
      if (!process.env.LOGIN_FAIL) fs.writeFileSync(process.env.HOME + '/logged', '');
      else process.exit(1);
    }
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
      if (cmd.includes('bm uninstall')) { console.log(process.env.UNINSTALL_FAIL ? 'error: bundle not found' : 'uninstall bundle successfully.'); }
      if (cmd.includes('bm dump')) { console.log('{\\n  "bundleName": "' + cmd.split(' ').pop() + '",\\n  "versionName": "1.2.3",\\n  "irrelevant": 1\\n}'); }
    }
  `);
  tool("param", `console.log('45678');`);
  tool("aa", prelude + `if (process.env.AA_FAIL) process.exit(1);`);
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
    HAP_SIGN_TOOL:signer, HAP_INSTALLER_AA:path.join(bin,'aa'), HAP_INSTALLER_PREPARE:path.join(__dirname,'prepare-profile.cjs')};
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

test('--sign-only signs and stops without touching hdc or the device', t => {
  const f=fixture(t); const out=path.join(f.root,'out','signed.hap');
  const r=f.run(['--sign-only','--output',out]); assert.equal(r.status,0,r.stdout+r.stderr);
  assert.ok(fs.existsSync(out)); assert.match(r.stdout,/Signed HAP: /);
  assert.ok(!f.calls().some(c=>c[0]==='hdc'||c[0]==='param'));
});
test('--sign-only still rejects a HAP whose bundle does not match', t => {
  const f=fixture(t); f.manifest(basic,'com.example.wrong');
  const r=f.run(['--sign-only']); assert.notEqual(r.status,0); assert.match(r.stderr,/bundle/i);
});
test('own keystore bypasses DevEco account, project and profile generation', t => {
  const f=fixture(t); const r=f.run(['--keystore','k.p12','--cert','c.cer','--profile-file','p.p7b','--key-alias','a'],{EXTERNAL:'1'});
  assert.equal(r.status,0,r.stdout+r.stderr);
  const calls=f.calls(); assert.ok(!calls.some(c=>c[0]==='devecocli'));
  const signer=calls.find(c=>c[0]==='signer'); assert.ok(signer.includes('--keystore')&&signer.includes('--key-alias'));
  assert.ok(!signer.includes('--profile'));
  assert.ok(!signer.some(a=>/pass|secret/i.test(a)));
});
test('--keystore needs the rest of the signing material and excludes --profile', t => {
  const f=fixture(t);
  let r=f.run(['--keystore','k.p12']); assert.equal(r.status,2); assert.match(r.stderr,/--cert/);
  r=f.run(['--keystore','k.p12','--cert','c','--profile-file','p','--key-alias','a','--profile','x']);
  assert.equal(r.status,2); assert.match(r.stderr,/mutually exclusive/);
});
test('--method validates its value, and sideload is refused while the system has none', t => {
  const f=fixture(t);
  let r=f.run(['--method','bogus']); assert.equal(r.status,2); assert.match(r.stderr,/invalid --method/);
  r=f.run(['--method','sideload']); assert.notEqual(r.status,0); assert.match(r.stderr,/sideloading is not available/);
  assert.ok(!f.calls().some(c=>c[0]==='devecocli'||c.includes('send')));
  r=f.run(['--method','hdc']); assert.equal(r.status,0,r.stdout+r.stderr);
});
test('uninstall and info address the chosen device', t => {
  const f=fixture(t);
  let r=spawnSync('bash',[script,'uninstall','--bundle-id',bundle,'--hdc',f.hdc,'--device','chosen'],{env:f.env,encoding:'utf8'});
  assert.equal(r.status,0,r.stdout+r.stderr); assert.match(r.stdout,/uninstall bundle successfully/);
  assert.ok(f.calls().some(c=>c.join(' ').includes('-t chosen shell bm uninstall -n '+bundle)));
  r=spawnSync('bash',[script,'info','--bundle-id',bundle,'--hdc',f.hdc,'--device','chosen'],{env:f.env,encoding:'utf8'});
  assert.equal(r.status,0,r.stdout+r.stderr); assert.match(r.stdout,/"versionName": "1.2.3"/); assert.doesNotMatch(r.stdout,/irrelevant/);
});
test('failed uninstall reports an error', t => {
  const f=fixture(t);
  const r=spawnSync('bash',[script,'uninstall','--bundle-id',bundle,'--hdc',f.hdc,'--device','x'],{env:{...f.env,UNINSTALL_FAIL:'1'},encoding:'utf8'});
  assert.notEqual(r.status,0); assert.match(r.stderr,/did not report successful uninstallation/);
});
test('doctor reports problems with a hint and exits non-zero when no device is connected', t => {
  const f=fixture(t);
  const r=spawnSync('bash',[script,'doctor','--hdc',f.hdc],{env:{...f.env,TEST_TARGETS:'local TCP Offline localhost hdc'},encoding:'utf8'});
  assert.equal(r.status,1,r.stdout+r.stderr); assert.match(r.stdout,/PROBLEM  hdc target connected \(0\)/);
  assert.match(r.stdout,/system sideloading not available/);
});
test('the legacy project directory is reused only while the new one is absent', t => {
  const f=fixture(t); fs.mkdirSync(path.join(f.root,'.hap-installer/projects/'+bundle+'/AppScope'),{recursive:true});
  fs.writeFileSync(path.join(f.root,'.hap-installer/projects/'+bundle+'/AppScope/app.json5'),'{}');
  fs.writeFileSync(path.join(f.root,'.hap-installer/projects/'+bundle+'/build-profile.json5'),'{}');
  fs.mkdirSync(path.join(f.root,'.hap-installer/projects/'+bundle+'/entry/src/main'),{recursive:true});
  fs.writeFileSync(path.join(f.root,'.hap-installer/projects/'+bundle+'/entry/src/main/module.json5'),'{module:{name:"entry"}}');
  const r=f.run(); assert.equal(r.status,0,r.stdout+r.stderr);
  assert.ok(!f.calls().some(c=>c[0]==='devecocli'&&c[1]==='create'));
  assert.ok(!fs.existsSync(path.join(f.root,'.app-installer')));
});
test('profile expiry is read from the p7b and warned about before signing', t => {
  const f=fixture(t); const dir=path.join(f.root,'proj'); fs.mkdirSync(dir);
  const p7b=path.join(dir,'p.p7b'); const notAfter=Math.floor(Date.now()/1000)-3.5*86400;
  fs.writeFileSync(p7b,`binary\x00{"validity":{"not-before":1,"not-after":${notAfter}}}\x00more`);
  fs.writeFileSync(path.join(dir,'build-profile.json5'),JSON.stringify({app:{signingConfigs:[{name:'default',material:{profile:'p.p7b'}}]}}));
  const days=spawnSync(process.execPath,[path.join(__dirname,'prepare-profile.cjs'),'--expiry',path.join(dir,'build-profile.json5')],{env:f.env,encoding:'utf8'});
  assert.equal(days.status,0); assert.equal(days.stdout.trim(),'-4');
  fs.writeFileSync(path.join(dir,'build-profile.json5'),'{}');
  const unknown=spawnSync(process.execPath,[path.join(__dirname,'prepare-profile.cjs'),'--expiry',path.join(dir,'build-profile.json5')],{env:f.env,encoding:'utf8'});
  assert.equal(unknown.status,0); assert.equal(unknown.stdout,'');
});

test('first login opens the login URL in the browser through aa start', t => {
  const f=fixture(t); const r=f.run([],{NEED_LOGIN:'1'}); assert.equal(r.status,0,r.stdout+r.stderr);
  const aa=f.calls().filter(c=>c[0]==='aa'); assert.equal(aa.length,1);
  assert.deepEqual(aa[0].slice(1),['start','-b','com.huawei.hmos.browser','-a','MainAbility','-U','https://developer.huawei.com/consumer/cn/oauth?code=1&x=a%20b']);
  assert.match(r.stdout,/Opened the login page/); assert.match(r.stdout,/Waiting for login/);
});
test('no browser is opened when already logged in or with --no-browser', t => {
  const f=fixture(t); let r=f.run(); assert.equal(r.status,0,r.stdout+r.stderr);
  assert.ok(!f.calls().some(c=>c[0]==='aa'));
  const g=fixture(t); r=g.run(['--no-browser'],{NEED_LOGIN:'1'}); assert.equal(r.status,0,r.stdout+r.stderr);
  assert.ok(!g.calls().some(c=>c[0]==='aa')); assert.match(r.stdout,/https:\/\/developer\.huawei\.com/);
});
test('a browser that cannot be opened only asks for a manual open and login still completes', t => {
  const f=fixture(t); const r=f.run([],{NEED_LOGIN:'1',AA_FAIL:'1'}); assert.equal(r.status,0,r.stdout+r.stderr);
  assert.match(r.stdout,/Could not open the browser automatically/);
});
test('a failed login stops before any project or signing work', t => {
  const f=fixture(t); const r=f.run([],{NEED_LOGIN:'1',LOGIN_FAIL:'1'}); assert.notEqual(r.status,0);
  assert.ok(!f.calls().some(c=>c[0]==='devecocli'&&(c[1]==='create'||c[1]==='signature')));
  assert.ok(!f.calls().some(c=>c.includes('send')));
});
