'use strict';

const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

function argument(name) {
  const index = process.argv.indexOf(name);
  if (index < 0 || !process.argv[index + 1]) throw new Error(`missing ${name}`);
  return process.argv[index + 1];
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, { stdio: 'inherit', ...options });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(`${command} exited with ${result.status}`);
}

const request = JSON.parse(fs.readFileSync(argument('--request'), 'utf8'));
if (request.variant !== 'acl') throw new Error(`unsupported OpenCode Desktop variant: ${request.variant}`);
if (!request.variant_definition.module_overlay) throw new Error('ACL module overlay is missing');

const extracted = path.join(request.tree, 'hap');
fs.mkdirSync(extracted, { mode: 0o700 });
run('unzip', ['-q', request.unsigned_hap, '-d', extracted]);

const personalizedConfig = path.join(request.personalized_tree, 'config.json');
const appConfig = path.join(extracted, 'resources/resfile/resources/app/config.json');
if (!fs.existsSync(personalizedConfig) || !fs.existsSync(appConfig)) {
  throw new Error('personalized config or HAP config.json is missing');
}
fs.copyFileSync(personalizedConfig, appConfig);
fs.copyFileSync(request.variant_definition.module_overlay, path.join(extracted, 'module.json'));

fs.rmSync(request.out_hap, { force: true });
run('zip', ['-qr', request.out_hap, '.'], { cwd: extracted });
