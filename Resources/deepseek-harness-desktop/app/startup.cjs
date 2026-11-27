'use strict';
const { StringDecoder } = require('node:string_decoder');
function isServerUrl(value, port) {
  if (typeof value !== 'string') return false;
  try {
    const url = new URL(value);
    return url.protocol === 'http:' && url.hostname === '127.0.0.1' &&
      Number(url.port) === port && !url.username && !url.password &&
      Boolean(url.searchParams.get('token'));
  } catch { return false; }
}
function createUrlCollector(port, onUrl) {
  const decoder = new StringDecoder('utf8');
  let pending = '';
  return chunk => {
    pending += Buffer.isBuffer(chunk) ? decoder.write(chunk) : chunk;
    const lines = pending.split('\n');
    pending = lines.pop().slice(-16384);
    for (const line of lines) {
      const clean = line.replace(/\x1b\[[0-?]*[ -/]*[@-~]/g, '');
      const urls = clean.match(/https?:\/\/\S+/g) || [];
      const found = urls.filter(value => isServerUrl(value, port));
      if (found.length) onUrl(found[found.length - 1]);
    }
  };
}
module.exports = { isServerUrl, createUrlCollector };
