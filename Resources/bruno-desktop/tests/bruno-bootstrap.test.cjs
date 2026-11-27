'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const src = fs.readFileSync(path.join(__dirname, '..', 'app', 'bruno-bootstrap.cjs'), 'utf8');

// Must stub node-pty (native addon cannot load on OHOS) before loading vendor main.
assert.match(src, /Module\._load/, 'must intercept module loading');
assert.match(src, /'@lydell\/node-pty'/, 'must stub node-pty');
assert.match(src, /vendor\.asar/, 'must load vendor asar');
assert.match(src, /app\.setAppPath\(vendor\)/, 'must set the Electron app path');
assert.match(src, /vendorPackage\.main/, 'must load the vendor main entry');
assert.match(src, /process\.env\.PATH\s*=\s*config\.path/, 'must pass host PATH');
assert.match(src, /version.*package\.json.*version/s, 'must pin vendor version');
console.log('bruno-bootstrap tests: OK');
