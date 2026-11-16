'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createUrlCollector, isServerUrl } = require(process.env.DSH_APP_STARTUP_HELPER || '../app/startup.cjs');
const port = 12345;
const url = `http://127.0.0.1:${port}/?token=example-token`;
test('discovers the authenticated URL even when unrelated URLs were logged first', () => {
  const found = [];
  const collect = createUrlCollector(port, value => found.push(value));
  collect('Docs: https://example.invalid/help\n');
  collect(`dsh web: ${url}\n`);
  assert.deepEqual(found, [url]);
});
test('waits for a complete line across stdout chunks instead of accepting a partial token', () => {
  const found = [];
  const collect = createUrlCollector(port, value => found.push(value));
  collect(`dsh web: http://127.0.0.1:${port}/?token=exam`);
  assert.deepEqual(found, []);
  collect('ple-token\n');
  assert.deepEqual(found, [url]);
});
test('strips ANSI control sequences and accepts CRLF', () => {
  const found = [];
  createUrlCollector(port, value => found.push(value))(`\x1b[32mdsh web: ${url}\x1b[0m\r\n`);
  assert.deepEqual(found, [url]);
});
test('rejects non-loopback, foreign port, credential and empty-token URLs', () => {
  for (const value of ['https://example.com/?token=x', `http://127.0.0.1:${port + 1}/?token=x`, `http://user@127.0.0.1:${port}/?token=x`, `http://127.0.0.1:${port}/?token=`]) {
    assert.equal(isServerUrl(value, port), false, value);
  }
});
test('selects the newest matching URL on a completed line', () => {
  const found = [];
  const newer = url.replace('example-token', 'new-token');
  createUrlCollector(port, value => found.push(value))(`${url} ${newer}\n`);
  assert.deepEqual(found, [newer]);
});
test('bounds unfinished output and recovers on the next line', () => {
  const found = [];
  const collect = createUrlCollector(port, value => found.push(value));
  collect('x'.repeat(100000)); collect(`\ndsh web: ${url}\n`);
  assert.deepEqual(found, [url]);
});
