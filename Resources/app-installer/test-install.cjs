"use strict";
const { test } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const vm = require("node:vm");
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
      if (process.env.CAPTURE_NET_ENV) fs.writeFileSync(process.env.CAPTURE_NET_ENV, JSON.stringify({ca: process.env.NODE_EXTRA_CA_CERTS || '', proxy: process.env.HTTPS_PROXY || '', insecure: process.env.NODE_TLS_REJECT_UNAUTHORIZED || ''}));
      if (process.env.FAIL_TLS) { console.error('Network connection failed (SELF_SIGNED_CERT_IN_CHAIN)'); process.exit(1); }
      if (process.env.FAIL_PROFILE_REFRESH) { console.error('profile refresh rejected'); process.exit(1); }
      if (process.env.REFRESH_PROFILE) {
        const now = Math.floor(Date.now() / 1000);
        const validity = JSON.stringify({validity:{'not-before':now-86400,'not-after':now+30*86400}});
        fs.writeFileSync(process.env.REFRESH_PROFILE, Buffer.concat([Buffer.from('binary'), Buffer.from([0]), Buffer.from(validity), Buffer.from([0]), Buffer.from('tail')]));
      }
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
      if (cmd.includes('aa force-stop') && process.env.STOP_MISSING) { console.log('error: failed to force stop process.'); console.log('Error Code:10104002  Error Message:Failed to retrieve specified package information.'); }
      if (cmd.includes('aa start')) { console.log(process.env.START_FAIL ? 'screen locked' : 'start ability successfully'); }
      if (cmd.includes('bm uninstall')) { console.log(process.env.UNINSTALL_FAIL ? 'error: bundle not found' : 'uninstall bundle successfully.'); }
      if (cmd.includes('bm dump') && process.env.TEST_BM_DUMP) { console.log(fs.readFileSync(process.env.TEST_BM_DUMP, 'utf8')); }
      else if (cmd.includes('bm dump') && process.env.DUMP_FAIL) { console.log('error: failed to get information and the parameters may be wrong.'); }
      else if (cmd.includes('bm dump')) { console.log('{\\n  "bundleName": "' + cmd.split(' ').pop() + '",\\n  "versionName": "1.2.3",\\n  "irrelevant": 1\\n}'); }
    }
  `);
  tool("param", `console.log('45678');`);
  tool("aa", prelude + `if (process.env.AA_FAIL) process.exit(1);`);
  const signer = tool("signer", prelude + `if (process.env.SIGN_FAIL) process.exit(3); fs.copyFileSync(args[args.indexOf('--hap')+1], args[args.indexOf('--output')+1]);`);
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

test('an expired automatic profile is refreshed before signing and installing', t => {
  const f=fixture(t); const dir=path.join(f.root,'.app-installer/projects',bundle);
  fs.mkdirSync(path.join(dir,'AppScope'),{recursive:true});
  fs.mkdirSync(path.join(dir,'entry/src/main'),{recursive:true});
  fs.writeFileSync(path.join(dir,'AppScope/app.json5'),'{}');
  fs.writeFileSync(path.join(dir,'entry/src/main/module.json5'),'{module:{name:"entry",requestPermissions:[]}}');
  const p7b=path.join(dir,'debug.p7b');
  const now=Math.floor(Date.now()/1000);
  fs.writeFileSync(p7b,`binary\x00{"validity":{"not-before":${now-86400},"not-after":${now-3600}}}\x00more`);
  const buildProfile=path.join(dir,'build-profile.json5');
  fs.writeFileSync(buildProfile,JSON.stringify({app:{signingConfigs:[{name:'default',material:{profile:'debug.p7b'}}]}}));
  const expiry=()=>spawnSync(process.execPath,[path.join(__dirname,'prepare-profile.cjs'),'--expiry',buildProfile],{env:f.env,encoding:'utf8'});
  assert(Number(expiry().stdout)<0);
  const r=f.run([],{REFRESH_PROFILE:p7b}); assert.equal(r.status,0,r.stdout+r.stderr);
  assert(Number(expiry().stdout)>0);
  const generate=f.calls().findIndex(c=>c[0]==='devecocli'&&c[1]==='signature'&&c[2]==='generate');
  const signer=f.calls().findIndex(c=>c[0]==='signer');
  assert(generate>=0&&signer>generate,'signature generate must refresh the profile before the signer runs');
});

test('a failed profile refresh records sign and stops before signing or upload', t => {
  const f=fixture(t); const result=path.join(f.root,'result.json');
  const r=f.run([],{FAIL_PROFILE_REFRESH:'1',HAP_INSTALLER_RESULT_FILE:result});
  assert.notEqual(r.status,0,r.stdout+r.stderr);
  const recorded=JSON.parse(fs.readFileSync(result,'utf8'));
  assert.equal(recorded.stage,'profile-generate'); assert.equal(recorded.reason,'sign');
  assert.ok(!f.calls().some(c=>c[0]==='signer'||c.includes('send')));
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
test('info fails when the device reports the bundle is not installed', t => {
  const f=fixture(t);
  const r=spawnSync('bash',[script,'info','--bundle-id',bundle,'--hdc',f.hdc,'--device','chosen'],{env:{...f.env,DUMP_FAIL:'1'},encoding:'utf8'});
  assert.equal(r.status,1,r.stdout+r.stderr); assert.match(r.stderr,/failed to get information/); assert.match(r.stderr,/is it installed/);
  assert.doesNotMatch(r.stdout,/debug profile days left/);
});

function hapWithDirectories(f, comment) {
  const zip = new AdmZip();
  zip.addFile('module.json', Buffer.from(JSON.stringify({app:{bundleName:bundle}, module:{name:'electron', requestPermissions:basic}})));
  zip.addFile('libs/', Buffer.alloc(0));
  zip.addFile('libs/arm64-v8a/', Buffer.alloc(0));
  zip.addFile('libs/arm64-v8a/libdemo.so', Buffer.from('\x7fELF-demo-'.repeat(500)));
  zip.addFile('resources/', Buffer.alloc(0));
  zip.addFile('resources/index.txt', Buffer.from('index'));
  if (comment) zip.addZipComment(comment);
  zip.writeZip(f.hap);
}
const names = file => spawnSync('unzip', ['-Z1', file], {encoding:'utf8'}).stdout.split('\n').filter(Boolean);
test('directory entries are removed before signing, everything else is kept byte for byte', t => {
  const f=fixture(t); hapWithDirectories(f, 'a trailing comment'); const out=path.join(f.root,'out','signed.hap');
  assert.equal(names(f.hap).filter(n=>n.endsWith('/')).length,3);
  const r=f.run(['--sign-only','--output',out]); assert.equal(r.status,0,r.stdout+r.stderr);
  assert.match(r.stdout,/Removed 3 directory entries/);
  assert.deepEqual(names(out).sort(),['libs/arm64-v8a/libdemo.so','module.json','resources/index.txt']);
  assert.equal(spawnSync('unzip',['-tq',out]).status,0);
  const before=new AdmZip(f.hap), after=new AdmZip(out);
  for (const n of names(out)) assert.ok(before.readFile(n).equals(after.readFile(n)),n);
  assert.equal(after.getZipComment(),'a trailing comment');
  assert.deepEqual(fs.readdirSync(path.dirname(out)),['signed.hap']);
});
test('a HAP without directory entries is signed unchanged and not mentioned', t => {
  const f=fixture(t); const out=path.join(f.root,'signed.hap');
  const r=f.run(['--sign-only','--output',out]); assert.equal(r.status,0,r.stdout+r.stderr);
  assert.doesNotMatch(r.stdout,/directory entries/);
  assert.ok(fs.readFileSync(out).equals(fs.readFileSync(f.hap)));
});
test('a HAP that cannot be checked for directory entries is signed as it is, with a warning', t => {
  const f=fixture(t); hapWithDirectories(f); const out=path.join(f.root,'signed.hap');
  const wrapper=path.join(f.root,'prepare-wrapper.cjs');
  fs.writeFileSync(wrapper,`if (process.argv[2]==='--strip-dirs') process.exit(1); require(${JSON.stringify(path.join(__dirname,'prepare-profile.cjs'))});`);
  const r=f.run(['--sign-only','--output',out],{HAP_INSTALLER_PREPARE:wrapper}); assert.equal(r.status,0,r.stdout+r.stderr);
  assert.match(r.stderr,/could not check the HAP for directory entries/);
  assert.ok(fs.readFileSync(out).equals(fs.readFileSync(f.hap)));
});
test('a failing signer leaves no temporary HAP behind and its exit status is kept', t => {
  const f=fixture(t); hapWithDirectories(f); const out=path.join(f.root,'out','signed.hap');
  const r=f.run(['--sign-only','--output',out],{SIGN_FAIL:'1'}); assert.equal(r.status,3,r.stdout+r.stderr);
  assert.deepEqual(fs.readdirSync(path.dirname(out)),[]);
});
test('the HAP given to hdc installation is the one without directory entries', t => {
  const f=fixture(t); hapWithDirectories(f); const r=f.run(); assert.equal(r.status,0,r.stdout+r.stderr);
  const signerCall=f.calls().find(c=>c[0]==='signer'); const input=signerCall[signerCall.indexOf('--hap')+1];
  assert.match(input,/\.nodirs\.hap$/); assert.ok(!fs.existsSync(input));
});

// A real zip64 archive, written by hand because AdmZip cannot produce one: the
// classic end-of-central-directory record carries 0xFFFF / 0xFFFFFFFF
// placeholders and the real values live in the zip64 end record and locator,
// which is how `zip` marks archives it cannot describe in 32 bits. The entries
// include directory entries, so a rewrite that ignored zip64 would drop them.
function crc32(data) {
  let crc = 0xffffffff;
  for (const byte of data) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit += 1) crc = (crc >>> 1) ^ (0xedb88320 & -(crc & 1));
  }
  return (crc ^ 0xffffffff) >>> 0;
}
function writeZip64Hap(file) {
  const entries = [
    ['module.json', Buffer.from(JSON.stringify({app:{bundleName:bundle}, module:{name:'electron', requestPermissions:basic}}))],
    ['libs/', Buffer.alloc(0)],
    ['libs/arm64-v8a/', Buffer.alloc(0)],
    ['libs/arm64-v8a/libdemo.so', Buffer.from('\x7fELF-demo-'.repeat(100))],
  ];
  const locals = [], centrals = [];
  let offset = 0;
  for (const [name, data] of entries) {
    const nameBytes = Buffer.from(name);
    const local = Buffer.alloc(30);
    local.writeUInt32LE(0x04034b50, 0); local.writeUInt16LE(45, 4); local.writeUInt16LE(0, 6); local.writeUInt16LE(0, 8);
    local.writeUInt16LE(0, 10); local.writeUInt16LE(33, 12); local.writeUInt32LE(crc32(data), 14);
    local.writeUInt32LE(data.length, 18); local.writeUInt32LE(data.length, 22); local.writeUInt16LE(nameBytes.length, 26);
    const central = Buffer.alloc(46);
    central.writeUInt32LE(0x02014b50, 0); central.writeUInt16LE(45, 4); central.writeUInt16LE(45, 6);
    central.writeUInt16LE(0, 8); central.writeUInt16LE(0, 10); central.writeUInt16LE(0, 12); central.writeUInt16LE(33, 14);
    central.writeUInt32LE(crc32(data), 16); central.writeUInt32LE(data.length, 20); central.writeUInt32LE(data.length, 24);
    central.writeUInt16LE(nameBytes.length, 28); central.writeUInt32LE(offset, 42);
    locals.push(local, nameBytes, data); centrals.push(central, nameBytes);
    offset += local.length + nameBytes.length + data.length;
  }
  const centralDirectory = Buffer.concat(centrals);
  const zip64End = Buffer.alloc(56);
  zip64End.writeUInt32LE(0x06064b50, 0); zip64End.writeBigUInt64LE(44n, 4); zip64End.writeUInt16LE(45, 12); zip64End.writeUInt16LE(45, 14);
  zip64End.writeBigUInt64LE(BigInt(entries.length), 24); zip64End.writeBigUInt64LE(BigInt(entries.length), 32);
  zip64End.writeBigUInt64LE(BigInt(centralDirectory.length), 40); zip64End.writeBigUInt64LE(BigInt(offset), 48);
  const locator = Buffer.alloc(20);
  locator.writeUInt32LE(0x07064b50, 0); locator.writeBigUInt64LE(BigInt(offset + centralDirectory.length), 8); locator.writeUInt32LE(1, 16);
  const end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50, 0); end.writeUInt16LE(0xffff, 8); end.writeUInt16LE(0xffff, 10);
  end.writeUInt32LE(0xffffffff, 12); end.writeUInt32LE(0xffffffff, 16);
  fs.writeFileSync(file, Buffer.concat([...locals, centralDirectory, zip64End, locator, end]));
}
test('--strip-dirs refuses a zip64 HAP and writes nothing', t => {
  const f=fixture(t); writeZip64Hap(f.hap); const out=path.join(f.root,'copy.hap');
  const r=spawnSync(process.execPath,[path.join(__dirname,'prepare-profile.cjs'),'--strip-dirs',f.hap,out],{env:f.env,encoding:'utf8'});
  assert.equal(r.status,1); assert.match(r.stderr,/zip64 is not supported/); assert.equal(r.stdout,'');
  assert.ok(!fs.existsSync(out));
});
test('a zip64 HAP is signed as it is, with a warning, and never rewritten', t => {
  const f=fixture(t); writeZip64Hap(f.hap); const original=fs.readFileSync(f.hap); const out=path.join(f.root,'out','signed.hap');
  assert.equal(spawnSync('unzip',['-tq',f.hap]).status,0);
  assert.equal(names(f.hap).filter(n=>n.endsWith('/')).length,2);
  const r=f.run(['--sign-only','--output',out]); assert.equal(r.status,0,r.stdout+r.stderr);
  assert.match(r.stderr,/could not check the HAP for directory entries; signing it as it is/);
  assert.doesNotMatch(r.stdout,/Removed/);
  assert.ok(fs.readFileSync(out).equals(original)); assert.ok(fs.readFileSync(f.hap).equals(original));
  assert.equal(names(out).filter(n=>n.endsWith('/')).length,2);
  assert.deepEqual(fs.readdirSync(path.dirname(out)),['signed.hap']);
});

test('ready reports one device and the login state without touching anything', t => {
  const f=fixture(t);
  const ready = (overrides={}) => spawnSync('bash',[script,'ready'],{env:{...f.env,...overrides},encoding:'utf8'});
  let r=ready(); assert.equal(r.status,0,r.stdout+r.stderr); assert.equal(r.stdout.trim(),'ok local');
  r=ready({NEED_LOGIN:'1'}); assert.equal(r.status,1); assert.equal(r.stdout.trim(),'no-login');
  r=ready({TEST_TARGETS:'local TCP Offline localhost hdc'}); assert.equal(r.status,1); assert.equal(r.stdout.trim(),'no-device');
  r=spawnSync('bash',[script,'ready','--hdc','/nonexistent/hdc'],{env:f.env,encoding:'utf8'});
  assert.equal(r.status,1); assert.equal(r.stdout.trim(),'no-hdc');
  assert.ok(!f.calls().some(c=>c[0]==='signer'||c.join(' ').includes('bm install')), 'ready must not sign or install');
});
test('login runs the DevEco login once and reports the result', t => {
  const f=fixture(t);
  let r=spawnSync('bash',[script,'login','--no-browser'],{env:{...f.env,NEED_LOGIN:'1'},encoding:'utf8'});
  assert.equal(r.status,0,r.stdout+r.stderr); assert.match(r.stdout,/logged in/);
  assert.ok(f.calls().some(c=>c.join(' ').includes('auth login')));
  r=spawnSync('bash',[script,'login','--no-browser'],{env:{...f.env,NEED_LOGIN:'1'},encoding:'utf8'});
  assert.equal(r.status,0,r.stdout+r.stderr); assert.match(r.stdout,/already logged in/);
});
function permissionDefinitions(f, entries) {
  const file=path.join(f.root,'definitions.json');
  fs.writeFileSync(file, JSON.stringify({definePermissions:entries}));
  return file;
}
function permissionDump(f, names, states) {
  const file=path.join(f.root,`dump-${names.length}-${states.join('_')}.json`);
  fs.writeFileSync(file, JSON.stringify({reqPermissions:names, reqPermissionStates:states}));
  return file;
}
test('permissions fails only for install-time permissions, not for pending user_grant ones', t => {
  const f=fixture(t);
  const definitions=permissionDefinitions(f,[{name:'ohos.permission.INTERNET',grantMode:'system_grant'},{name:'ohos.permission.READ_PASTEBOARD',grantMode:'user_grant'}]);
  const ok=permissionDump(f,['ohos.permission.INTERNET','ohos.permission.READ_PASTEBOARD'],[0,-1]);
  let r=spawnSync('bash',[script,'permissions','--bundle-id',bundle],{env:{...f.env,HAP_INSTALLER_PERMISSIONS:definitions,TEST_BM_DUMP:ok},encoding:'utf8'});
  assert.equal(r.status,0,r.stdout+r.stderr);
  assert.match(r.stdout,/pending ohos.permission.READ_PASTEBOARD user_grant/);
  assert.match(r.stdout,/permissions: 1 granted, 1 user_grant, 0 missing/);
  const bad=permissionDump(f,['ohos.permission.INTERNET'],[-1]);
  r=spawnSync('bash',[script,'permissions','--bundle-id',bundle],{env:{...f.env,HAP_INSTALLER_PERMISSIONS:definitions,TEST_BM_DUMP:bad},encoding:'utf8'});
  assert.equal(r.status,1); assert.match(r.stdout,/missing ohos.permission.INTERNET system_grant state=-1/);
});
test('permissions with --expect-acl proves the ACL variant was installed', t => {
  const f=fixture(t);
  const definitions=permissionDefinitions(f,[{name:'ohos.permission.INTERNET',grantMode:'system_grant'},{name:'ohos.permission.CUSTOM_SANDBOX',grantMode:'system_grant'}]);
  const dump=permissionDump(f,['ohos.permission.INTERNET'],[0]);
  const acl=path.join(f.root,'module-acl.json');
  fs.writeFileSync(acl, JSON.stringify({module:{requestPermissions:[{name:'ohos.permission.INTERNET'},{name:'ohos.permission.CUSTOM_SANDBOX'}]}}));
  const r=spawnSync('bash',[script,'permissions','--bundle-id',bundle,'--expect-acl',acl],{env:{...f.env,HAP_INSTALLER_PERMISSIONS:definitions,TEST_BM_DUMP:dump},encoding:'utf8'});
  assert.equal(r.status,1);
  assert.match(r.stdout,/missing-variant ohos.permission.CUSTOM_SANDBOX/);
});
test('HAP_INSTALLER_NO_START installs without starting the app', t => {
  const f=fixture(t); const r=f.run([],{HAP_INSTALLER_NO_START:'1'});
  assert.equal(r.status,0,r.stdout+r.stderr);
  assert.ok(!f.calls().some(c=>c.join(' ').includes('aa start')));
});
test('HAP_INSTALLER_DEVICE is used for every device operation', t => {
  const f=fixture(t); const r=f.run([],{HAP_INSTALLER_DEVICE:'fromenv'});
  assert.equal(r.status,0,r.stdout+r.stderr);
  const operations=f.calls().filter(c=>c[0]==='hdc'&&c[1]!=='list');
  assert.ok(operations.length>0); assert.ok(operations.every(c=>c[1]==='-t'&&c[2]==='fromenv'));
});
test('HAP_INSTALLER_NO_LOGIN stops before the DevEco login when not signed in', t => {
  const f=fixture(t); const r=f.run([],{NEED_LOGIN:'1',HAP_INSTALLER_NO_LOGIN:'1'});
  assert.equal(r.status,3,r.stdout+r.stderr);
  assert.match(r.stderr,/HAP_INSTALLER_NO_LOGIN/);
  assert.ok(!f.calls().some(c=>c.join(' ').includes('auth login')));
  assert.ok(!f.calls().some(c=>c[0]==='signer'));
});

test('tls_ca and https_proxy come from ~/.app-installer/config', t => {
  const f = fixture(t);
  const ca = path.join(f.root, 'ca.pem');
  fs.writeFileSync(ca, '-----BEGIN CERTIFICATE-----\n');
  fs.mkdirSync(path.join(f.root, '.app-installer'));
  fs.writeFileSync(path.join(f.root, '.app-installer', 'config'),
    `tls_ca=${ca}\nhttps_proxy=http://127.0.0.1:7890\n`);
  const capture = path.join(f.root, 'net-env.json');
  const r = f.run([], { CAPTURE_NET_ENV: capture });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.deepEqual(JSON.parse(fs.readFileSync(capture, 'utf8')),
    { ca, proxy: 'http://127.0.0.1:7890', insecure: '' });
});

test('tls_insecure=1 disables certificate verification for the DevEco CLI', t => {
  const f = fixture(t);
  fs.mkdirSync(path.join(f.root, '.app-installer'));
  fs.writeFileSync(path.join(f.root, '.app-installer', 'config'), 'tls_insecure=1\n');
  const capture = path.join(f.root, 'net-env.json');
  const r = f.run([], { CAPTURE_NET_ENV: capture });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.equal(JSON.parse(fs.readFileSync(capture, 'utf8')).insecure, '0');
  assert.match(r.stderr, /tls_insecure=1 — TLS certificate verification is disabled/);
});

test('a TLS trust failure records tls and prints the CA hint', t => {
  const f = fixture(t);
  const result = path.join(f.root, 'result.json');
  const r = f.run([], { FAIL_TLS: '1', HAP_INSTALLER_RESULT_FILE: result });
  assert.notEqual(r.status, 0);
  assert.match(r.stderr, /tls_ca=\/path\/to\/ca\.pem/);
  assert.equal(JSON.parse(fs.readFileSync(result, 'utf8')).reason, 'tls');
});

test('a tls_ca that does not exist fails before any DevEco call', t => {
  const f = fixture(t);
  fs.mkdirSync(path.join(f.root, '.app-installer'));
  fs.writeFileSync(path.join(f.root, '.app-installer', 'config'),
    `tls_ca=${path.join(f.root, 'missing.pem')}\n`);
  const r = f.run();
  assert.notEqual(r.status, 0);
  assert.match(r.stderr, /tls_ca is not a file/);
  assert.ok(!f.calls().some(c => c[0] === 'devecocli'));
});

test('a force-stop of a package that is not installed stays quiet', t => {
  const f = fixture(t);
  const r = f.run([], { STOP_MISSING: '1' });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.doesNotMatch(r.stdout + r.stderr, /10104002|not installed/);
});

test('doctor reports the configured TLS CA', t => {
  const f = fixture(t);
  const ca = path.join(f.root, 'ca.pem');
  fs.writeFileSync(ca, 'x');
  fs.mkdirSync(path.join(f.root, '.app-installer'));
  fs.writeFileSync(path.join(f.root, '.app-installer', 'config'), `tls_ca=${ca}\n`);
  const r = spawnSync('bash', [script, 'doctor'], { env: f.env, encoding: 'utf8' });
  assert.match(r.stdout + r.stderr, /TLS config \(tls_ca=/);
});

test('doctor --network reports a reachable endpoint', t => {
  const f = fixture(t);
  const probe = path.join(f.root, 'probe');
  fs.writeFileSync(probe, `#!${process.execPath}\nconsole.log('HTTP 200');\n`);
  fs.chmodSync(probe, 0o755);
  const r = spawnSync('bash', [script, 'doctor', '--network'], {
    env: { ...f.env, HAP_INSTALLER_NETWORK_PROBE_CMD: probe, HTTPS_PROXY: '', https_proxy: '' },
    encoding: 'utf8',
  });
  assert.match(r.stdout + r.stderr, /network probe \(HTTP 200\)/);
});

test('doctor --network reports an untrusted certificate chain', t => {
  const f = fixture(t);
  const probe = path.join(f.root, 'probe');
  fs.writeFileSync(probe, `#!${process.execPath}\nconsole.error('SELF_SIGNED_CERT_IN_CHAIN'); process.exit(1);\n`);
  fs.chmodSync(probe, 0o755);
  const r = spawnSync('bash', [script, 'doctor', '--network'], {
    env: { ...f.env, HAP_INSTALLER_NETWORK_PROBE_CMD: probe, HTTPS_PROXY: '', https_proxy: '' },
    encoding: 'utf8',
  });
  assert.match(r.stdout + r.stderr, /TLS trust probe/);
  assert.match(r.stdout + r.stderr, /tls_ca=/);
});

// The DevEco CLI is minified: the decoder class name and its path/crypto/fs/log
// aliases change between releases (Rs/W/Um/we in 1.3.10, Os/V/Jm/ye in 1.3.12).
const signer = require(path.join(__dirname, 'sign-hap.cjs'));
const renamed = [
  { cls: 'Rs', path: 'W', crypto: 'Um', fs: 'we', log: 'm' },
  { cls: 'Os', path: 'V', crypto: 'Jm', fs: 'ye', log: 'm' },
  { cls: 'Zq', path: 'a$', crypto: 'Kb', fs: 'Lc', log: 'dbg' },
];
function decoderSource(n) {
  return `import"x";var ${n.cls}=class n{static decryptPwd(e,t,r){${n.log}(\`[DecipherUtil] \${r}\`);` +
    `return ${n.path}.resolve(e,"material")+"|"+${n.fs}.statSync("/").isDirectory()+"|"+` +
    `${n.crypto}.pbkdf2Sync("p","s",1,4,"sha256").length}};export{n as x};`;
}
function decode(source) {
  const cls = signer.extractDecoderClass(source);
  return vm.runInNewContext(`(${cls})`, { Buffer, Int8Array, ...signer.decoderGlobals(cls) })
    .decryptPwd('/cfg', 'x', 'storePassword');
}
function refuses(source, pattern) {
  const sign = JSON.stringify(path.join(__dirname, 'sign-hap.cjs'));
  const r = spawnSync(process.execPath, ['-e',
    `const s=require(${sign});s.decoderGlobals(s.extractDecoderClass(${JSON.stringify(source)}));`], { encoding: 'utf8' });
  assert.equal(r.status, 1);
  assert.match(r.stderr, pattern);
}

test('the signing decoder follows the minified class and alias names', () => {
  for (const names of renamed) assert.equal(decode(decoderSource(names)), '/cfg/material|true|4', names.cls);
});

test('the signing decoder refuses a layout it cannot identify', () => {
  refuses('var a=class n{};', /decoder is missing/);
  refuses('var a=class n{};var b={};static decryptPwd(', /does not contain decryptPwd/);
  refuses('var a=class n{static decryptPwd(e){m(`[DecipherUtil]`);return A.resolve(e)+B.join(e)+C.pbkdf2Sync()+D.statSync()}}',
    /path alias is ambiguous/);
});

test('the shipped DevEco CLI decoder runs with the derived aliases', { skip: !process.env.DEVECO_CLI_JS }, () => {
  const cls = signer.extractDecoderClass(fs.readFileSync(process.env.DEVECO_CLI_JS, 'utf8'));
  const decoder = vm.runInNewContext(`(${cls})`, { Buffer, Int8Array, ...signer.decoderGlobals(cls) });
  // Reaching the file system proves every alias is bound; a stale alias throws ReferenceError instead.
  assert.throws(() => decoder.decryptPwd('/nonexistent-deveco-config', 'ab'.repeat(20), 'storePassword'),
    { code: 'ENOENT' });
});
