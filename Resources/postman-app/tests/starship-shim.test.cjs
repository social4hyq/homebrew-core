'use strict';
const assert = require('node:assert/strict');
const starship = require('../app/starship-shim.cjs');

(async () => {
  assert.equal(typeof starship.operatingSystemArchitecture, 'string');
  assert.equal(starship.operatingSystemArchitecture, process.arch.replace('ia32', 'x86'));
  assert.equal(typeof starship.installationOptions.get, 'function');
  // No profile.json in the test env: defaults to null like Postman's built-in.
  assert.equal(await starship.installationOptions.get('DISABLE_INTERCEPTOR_PORT'), null);
  await assert.rejects(() => starship.installationOptions.get('bad-id'));
  console.log('starship-shim tests: OK');
})();
