'use strict';
// utilityProcess ignores execArgv/NODE_OPTIONS on OHOS, so the main process
// forks this wrapper instead; it preloads the shims and then runs the real
// vendor entry (path passed as --owl-real-entry=<path>).
const prefix = '--owl-real-entry=';
const index = process.argv.findIndex((arg) => typeof arg === 'string' && arg.startsWith(prefix));
if (index < 0) throw new Error('owl-real-entry argument missing');
const real = process.argv[index].slice(prefix.length);
process.argv.splice(index, 1);
require('./owl-sqlite-shim.cjs');
require(real);
