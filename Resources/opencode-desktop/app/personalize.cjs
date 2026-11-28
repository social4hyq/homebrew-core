'use strict';

const fs = require('node:fs');
const path = require('node:path');

function argument(name) {
  const index = process.argv.indexOf(name);
  if (index < 0 || !process.argv[index + 1]) throw new Error(`missing ${name}`);
  return process.argv[index + 1];
}

const request = JSON.parse(fs.readFileSync(argument('--request'), 'utf8'));
const host = request.host;
if (!host || typeof host.home !== 'string' || !host.home) {
  throw new Error('HOME is required to configure OpenCode Desktop');
}

const executable = (host.path || '').split(path.delimiter)
  .map((entry) => path.join(entry || '.', 'opencode'))
  .find((candidate) => {
    try { return fs.statSync(candidate).isFile(); } catch { return false; }
  });
if (!executable) throw new Error('cannot find opencode in the host PATH');

fs.mkdirSync(request.output_tree, { recursive: true, mode: 0o700 });
fs.writeFileSync(path.join(request.output_tree, 'config.json'), JSON.stringify({
  opencode: executable,
  host: {
    home: host.home,
    path: host.path,
    xdgConfig: host.xdg_config,
    xdgData: host.xdg_data,
    xdgState: host.xdg_state,
  },
}, null, 2) + '\n', { mode: 0o600 });
