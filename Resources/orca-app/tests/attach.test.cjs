'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');

const attach = require('../app/attach.cjs');

const origin = 'http://127.0.0.1:6768';

function readyLine(overrides = {}) {
  return JSON.stringify({
    type: 'orca_server_ready',
    schemaVersion: 1,
    runtimeId: 'runtime-a',
    endpoint: 'ws://127.0.0.1:6768',
    pairing: { available: true, webClientUrl: `${origin}/web-index.html#pairing=code-a` },
    ...overrides,
  });
}

function tempDir(t) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'orca-attach-'));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  return dir;
}

test('parseReadyRecord takes the first ready record and skips log lines', () => {
  const text = ['not json at all', '{"type":"other"}', readyLine(), readyLine({ runtimeId: 'runtime-b' })].join('\n');
  assert.deepEqual(attach.parseReadyRecord(text), {
    runtimeId: 'runtime-a',
    port: 6768,
    webClientUrl: `${origin}/web-index.html#pairing=code-a`,
  });
});

test('parseReadyRecord returns null without a usable record', () => {
  assert.equal(attach.parseReadyRecord(null), null);
  assert.equal(attach.parseReadyRecord(''), null);
  assert.equal(attach.parseReadyRecord('2026-11-22T03:12:28.051Z [orcad] relay offline\n'), null);
  assert.equal(attach.parseReadyRecord('orca_server_ready but {broken json'), null);
  assert.equal(attach.parseReadyRecord(readyLine({ runtimeId: '' })), null);
});

test('parseReadyRecord keeps a record without a pairing link, with its port', () => {
  const record = attach.parseReadyRecord(readyLine({ pairing: { available: false } }));
  assert.equal(record.webClientUrl, null);
  assert.equal(record.port, 6768);
});

test('readHead reads only the start of a file that keeps growing', (t) => {
  const file = path.join(tempDir(t), 'server.ready.json');
  const noise = '2026-11-22T03:12:28.051Z [orcad] some log line\n'.repeat(20000);
  fs.writeFileSync(file, readyLine() + '\n' + noise);
  const head = attach.readHead(file);
  assert.ok(head.length <= attach.HEAD_BYTES);
  assert.equal(attach.parseReadyRecord(head).runtimeId, 'runtime-a');
  assert.equal(attach.readHead(path.join(path.dirname(file), 'missing')), null);
});

test('readTail finds a recent connection in a large log', (t) => {
  const file = path.join(tempDir(t), 'server.ready.json');
  const noise = '2026-11-22T03:12:28.051Z [orcad] some log line\n'.repeat(20000);
  fs.writeFileSync(file, readyLine() + '\n' + noise +
    '2026-11-22T04:00:00.123Z [runtime-rpc] client connected device=d scope=runtime\n');
  const tail = attach.readTail(file);
  assert.ok(tail.length <= attach.TAIL_BYTES);
  assert.equal(attach.lastClientConnectedAt(tail), '2026-11-22T04:00:00.123Z');
  assert.equal(attach.readTail(path.join(path.dirname(file), 'missing')), null);
});

test('lastClientConnectedAt returns the latest connection or null', () => {
  const text = [
    '2026-11-22T03:00:00.000Z [runtime-rpc] client connected device=a scope=runtime',
    '2026-11-22T03:00:05.000Z [orcad] something else',
    '2026-11-22T03:10:00.500Z [runtime-rpc] client connected device=b scope=runtime',
    '2026-11-22T03:11:00.000Z [runtime-rpc] client disconnected device=b',
  ].join('\n');
  assert.equal(attach.lastClientConnectedAt(text), '2026-11-22T03:10:00.500Z');
  assert.equal(attach.lastClientConnectedAt('no connections here'), null);
  assert.equal(attach.lastClientConnectedAt(undefined), null);
  // A line that merely mentions the phrase in the middle is not a connection.
  assert.equal(attach.lastClientConnectedAt('note: [runtime-rpc] client connected'), null);
});

test('chooseTarget pairs with a runtime it has not seen', () => {
  const ready = attach.parseReadyRecord(readyLine());
  const target = attach.chooseTarget({ origin, ready, state: {} });
  assert.equal(target.kind, 'link');
  assert.equal(target.url, `${origin}/web-index.html#pairing=code-a`);
  assert.equal(target.runtimeId, 'runtime-a');
  assert.equal(target.reason, 'pair');
});

test('chooseTarget opens the plain client for a runtime it already paired with', () => {
  const ready = attach.parseReadyRecord(readyLine());
  const target = attach.chooseTarget({ origin, ready, state: { lastPairedRuntimeId: 'runtime-a' } });
  assert.equal(target.kind, 'plain');
  assert.equal(target.url, `${origin}/web-index.html`);
  assert.equal(target.reason, 'already-paired');
});

test('chooseTarget pairs again when the runtime was restarted', () => {
  const ready = attach.parseReadyRecord(readyLine({ runtimeId: 'runtime-b' }));
  const target = attach.chooseTarget({ origin, ready, state: { lastPairedRuntimeId: 'runtime-a' } });
  assert.equal(target.kind, 'link');
  assert.equal(target.runtimeId, 'runtime-b');
});

test('chooseTarget does not retry a link that was opened without a connection', () => {
  const ready = attach.parseReadyRecord(readyLine());
  const target = attach.chooseTarget({ origin, ready, state: { lastTriedRuntimeId: 'runtime-a' } });
  assert.equal(target.kind, 'plain');
  assert.equal(target.reason, 'link-not-confirmed');
});

test('chooseTarget ignores a record for another port, origin or without a link', () => {
  const plain = `${origin}/web-index.html`;
  const otherPort = attach.parseReadyRecord(readyLine({ endpoint: 'ws://127.0.0.1:6999' }));
  assert.deepEqual(attach.chooseTarget({ origin, ready: otherPort, state: {} }),
    { kind: 'plain', url: plain, runtimeId: null, reason: 'other-port' });

  const otherOrigin = attach.parseReadyRecord(readyLine({
    pairing: { webClientUrl: 'http://127.0.0.1:6999/web-index.html#pairing=x' },
  }));
  assert.equal(attach.chooseTarget({ origin, ready: otherOrigin, state: {} }).reason, 'other-origin');

  const foreign = attach.parseReadyRecord(readyLine({
    pairing: { webClientUrl: 'http://evil.example:6768/web-index.html#pairing=x' },
  }));
  assert.equal(attach.chooseTarget({ origin, ready: foreign, state: {} }).kind, 'plain');

  const noLink = attach.parseReadyRecord(readyLine({ pairing: { available: false } }));
  assert.equal(attach.chooseTarget({ origin, ready: noLink, state: {} }).reason, 'no-ready-record');
  assert.equal(attach.chooseTarget({ origin, ready: null, state: {} }).reason, 'no-ready-record');
});

test('chooseTarget tolerates a missing state object', () => {
  const ready = attach.parseReadyRecord(readyLine());
  assert.equal(attach.chooseTarget({ origin, ready }).kind, 'link');
});

test('state round trip, and a missing or corrupt file reads as empty', (t) => {
  const dir = tempDir(t);
  const file = path.join(dir, 'nested', 'attach.json');
  const empty = { lastPairedRuntimeId: null, lastTriedRuntimeId: null, pairedHostId: null };
  assert.deepEqual(attach.readState(file), empty);
  assert.equal(attach.writeState(file, { lastPairedRuntimeId: 'runtime-a', lastTriedRuntimeId: 'runtime-b', pairedHostId: 'installation:h' }), true);
  assert.deepEqual(attach.readState(file), { lastPairedRuntimeId: 'runtime-a', lastTriedRuntimeId: 'runtime-b', pairedHostId: 'installation:h' });
  fs.writeFileSync(file, '{not json');
  assert.deepEqual(attach.readState(file), empty);
  fs.writeFileSync(file, JSON.stringify({ lastPairedRuntimeId: 42, lastTriedRuntimeId: '' }));
  assert.deepEqual(attach.readState(file), empty);
});

test('writeState reports failure instead of throwing', (t) => {
  const dir = tempDir(t);
  const blocker = path.join(dir, 'file');
  fs.writeFileSync(blocker, 'x');
  assert.equal(attach.writeState(path.join(blocker, 'sub', 'attach.json'), {}), false);
});

// A web client link as the runtime prints it.
function linkFor(payload) {
  const code = Buffer.from(JSON.stringify(payload)).toString('base64url');
  return `${origin}/web-index.html#pairing=${encodeURIComponent('orca://pair?code=' + code)}`;
}

test('hostIdOf names the host a link is for, by installation id first, else by key', () => {
  assert.equal(attach.hostIdOf(linkFor({ v: 2, publicKeyB64: 'k1', hostDescriptor: { installationId: 'i1' } })), 'installation:i1');
  assert.equal(attach.hostIdOf(linkFor({ v: 2, publicKeyB64: 'k1' })), 'key:k1');
  assert.equal(attach.hostIdOf(`${origin}/web-index.html#pairing=code-a`), null, 'not a readable code');
  assert.equal(attach.hostIdOf(`${origin}/web-index.html`), null);
  assert.equal(attach.hostIdOf('not a url'), null);
  const raw = Buffer.from(JSON.stringify({ v: 2, hostDescriptor: { installationId: 'i2' } })).toString('base64url');
  assert.equal(attach.hostIdOf(`${origin}/web-index.html#pairing=${raw}`), 'installation:i2', 'a bare code works too');
  assert.equal(attach.hostIdOf(`${origin}/web-index.html?code=${raw}`), 'installation:i2', 'and so does a query');
});

test('needsFreshSavedServer is true only for a link for another or unknown host', () => {
  const link = linkFor({ v: 2, hostDescriptor: { installationId: 'i1' } });
  assert.equal(attach.needsFreshSavedServer({ url: link, state: { pairedHostId: 'installation:i2' } }), true);
  assert.equal(attach.needsFreshSavedServer({ url: link, state: { pairedHostId: null } }), true);
  assert.equal(attach.needsFreshSavedServer({ url: link, state: {} }), true);
  assert.equal(attach.needsFreshSavedServer({ url: link }), true);
  assert.equal(attach.needsFreshSavedServer({ url: link, state: { pairedHostId: 'installation:i1' } }), false);
  assert.equal(attach.needsFreshSavedServer({ url: `${origin}/web-index.html`, state: {} }), false, 'a plain page has no link');
});

test('chooseTarget gives the link target the host it is for', () => {
  const ready = attach.parseReadyRecord(readyLine({
    pairing: { available: true, webClientUrl: linkFor({ v: 2, hostDescriptor: { installationId: 'i9' } }) },
  }));
  const target = attach.chooseTarget({ origin, ready, state: {} });
  assert.equal(target.kind, 'link');
  assert.equal(target.hostId, 'installation:i9');
});

test('publishRuntimeProfile copies orca-runtime.json for the runtime that announced itself', (t) => {
  const root = tempDir(t);
  const home = path.join(root, 'home');
  const dataRoot = path.join(root, 'data');
  fs.mkdirSync(dataRoot);
  const record = JSON.stringify({ runtimeId: 'r1', pid: 12, transports: [], authToken: 'tok' });
  fs.writeFileSync(path.join(dataRoot, 'orca-runtime.json'), record);
  assert.equal(attach.publishRuntimeProfile({ dataRoot, home, runtimeId: 'r1' }), true);
  const copy = path.join(attach.profileDir(home), 'orca-runtime.json');
  assert.equal(fs.readFileSync(copy, 'utf8'), record);
  assert.equal(attach.publishRuntimeProfile({ dataRoot, home, runtimeId: 'r2' }), false, 'another runtime\'s file');
  assert.equal(attach.publishRuntimeProfile({ dataRoot: path.join(root, 'nope'), home, runtimeId: 'r1' }), false);
  fs.writeFileSync(path.join(dataRoot, 'orca-runtime.json'), 'junk');
  assert.equal(attach.publishRuntimeProfile({ dataRoot, home, runtimeId: 'r1' }), false);
});

test('unpublishRuntimeProfile removes only the profile of the runtime it is told', (t) => {
  const root = tempDir(t);
  const home = path.join(root, 'home');
  const dir = attach.profileDir(home);
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, 'orca-runtime.json'), JSON.stringify({ runtimeId: 'r1' }));
  assert.equal(attach.unpublishRuntimeProfile({ home, runtimeId: 'r2' }), false);
  assert.equal(fs.existsSync(path.join(dir, 'orca-runtime.json')), true);
  assert.equal(attach.unpublishRuntimeProfile({ home, runtimeId: 'r1' }), true);
  assert.equal(fs.existsSync(path.join(dir, 'orca-runtime.json')), false);
  assert.equal(attach.unpublishRuntimeProfile({ home, runtimeId: 'r1' }), false, 'already gone');
});
