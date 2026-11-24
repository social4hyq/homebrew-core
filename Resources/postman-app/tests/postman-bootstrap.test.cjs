'use strict';
// Static checks for the Postman bootstrap: it must hand the host PATH/HOME to
// child processes and load the vendor main from app/vendor/.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const src = fs.readFileSync(path.join(__dirname, '..', 'app', 'postman-bootstrap.cjs'), 'utf8');

assert.match(src, /process\.env\.PATH\s*=\s*config\.path/, 'must set PATH from host config');
assert.match(src, /process\.env\.HOME\s*=\s*config\.home/, 'must set HOME from host config');
assert.match(src, /app\.setAppPath\(vendor\)/, 'must set the Electron app path to vendor');
assert.match(src, /require\(path\.join\(vendor, vendorPackage\.main/, 'must load the vendor main module');
assert.match(src, /postman-host-config\.json/, 'must read the staged host config');
// Version pin guard must be present (vendor version == shell version).
assert.match(src, /vendorPackage\.version.*package\.json.*version/s, 'must pin vendor version');
console.log('postman-bootstrap tests: OK');
