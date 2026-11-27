'use strict';

try { require('./owl-host-shim.cjs'); } catch (e) { console.error('OWL_HOST shim failed', e && e.message); }

// Replace the bundled better-sqlite3 native addon with a synchronous shim on
// top of Node's built-in node:sqlite.  The official addon is a glibc/V8 addon
// built for Electron ABI 143 on linux-arm64, so it cannot be loaded by the
// OHOS Electron runtime.  The app only uses better-sqlite3's synchronous
// prepare/run/get/all/iterate/exec surface, which node:sqlite provides.
//
// Loaded from the main process bootstrap and (through --require) from the
// app's worker threads.

const Module = require('node:module');
const { DatabaseSync } = require('node:sqlite');

function normalize(value) {
  if (typeof value === 'boolean') return value ? 1 : 0;
  if (value === undefined) return null;
  return value;
}

function normalizeParams(params) {
  if (params.length === 1 && params[0] && typeof params[0] === 'object' &&
      !Array.isArray(params[0]) && !(params[0] instanceof Uint8Array)) {
    const source = params[0];
    const result = {};
    for (const [key, value] of Object.entries(source)) result[key] = normalize(value);
    return [result];
  }
  return params.map(normalize);
}

class Statement {
  #statement;
  #pluck = false;

  constructor(statement) {
    this.#statement = statement;
  }

  run(...params) {
    const result = this.#statement.run(...normalizeParams(params));
    return {
      changes: Number(result.changes),
      lastInsertRowid: result.lastInsertRowid,
    };
  }

  get(...params) {
    return this.#project(this.#plain(this.#statement.get(...normalizeParams(params))));
  }

  all(...params) {
    const rows = this.#statement.all(...normalizeParams(params));
    return this.#pluck ? rows.map((row) => Object.values(row)[0]) : rows.map((row) => this.#plain(row));
  }

  *iterate(...params) {
    for (const row of this.#statement.iterate(...normalizeParams(params))) {
      yield this.#project(this.#plain(row));
    }
  }

  pluck(toggle = true) {
    this.#pluck = toggle !== false;
    return this;
  }

  raw(toggle = true) {
    if (typeof this.#statement.setReturnArrays === 'function') {
      this.#statement.setReturnArrays(toggle !== false);
    }
    return this;
  }

  safeIntegers(toggle = true) {
    if (typeof this.#statement.setReadBigInts === 'function') {
      this.#statement.setReadBigInts(toggle !== false);
    }
    return this;
  }

  bind() {
    return this;
  }

  expand(toggle = true) {
    return this;
  }

  columns() {
    return this.#statement.columns();
  }

  // node:sqlite returns null-prototype rows; every consumer here (including
  // the app's RPC serializer) expects ordinary objects.
  #plain(row) {
    return row && typeof row === 'object' ? { ...row } : row;
  }

  #project(row) {
    if (this.#pluck && row) return Object.values(row)[0];
    return row;
  }
}

class Database {
  #database;
  #closed = false;
  #safeIntegers = false;

  constructor(filename, options = {}) {
    if (typeof filename !== 'string') {
      throw new TypeError('Database path must be a string');
    }
    this.name = filename;
    this.readonly = Boolean(options.readonly);
    this.#database = new DatabaseSync(filename, {
      readOnly: this.readonly,
      open: true,
      enableForeignKeyConstraints: options.foreignKeys !== false,
      enableDoubleQuotedStringLiterals: false,
    });
  }

  get open() {
    return !this.#closed;
  }

  get inTransaction() {
    return this.#database.isTransaction;
  }

  prepare(sql) {
    const statement = new Statement(this.#database.prepare(String(sql)));
    if (this.#safeIntegers) statement.safeIntegers(true);
    return statement;
  }

  exec(sql) {
    this.#database.exec(String(sql));
    return this;
  }

  close() {
    if (this.#closed) return this;
    this.#closed = true;
    this.#database.close();
    return this;
  }

  pragma(source, options = {}) {
    const statement = this.prepare(`PRAGMA ${source}`);
    if (options.simple) {
      const row = statement.get();
      return row ? Object.values(row)[0] : undefined;
    }
    return statement.all();
  }

  transaction(fn) {
    const run = (...args) => {
      this.exec('BEGIN');
      try {
        const result = fn(...args);
        this.exec('COMMIT');
        return result;
      } catch (error) {
        this.exec('ROLLBACK');
        throw error;
      }
    };
    return run;
  }

  defaultSafeIntegers(toggle = true) {
    this.#safeIntegers = toggle !== false;
    return this;
  }

  unsafeMode() {
    return this;
  }

  loadExtension(file) {
    this.#database.enableLoadExtension(true);
    this.#database.loadExtension(String(file));
    return this;
  }

  function(name, ...rest) {
    this.#database.function(String(name), rest.at(-1));
    return this;
  }

  aggregate(name, options) {
    this.#database.aggregate(String(name), options);
    return this;
  }

  backup(destination, options) {
    return this.#database.backup(String(destination), options);
  }

  serialize() {
    return this;
  }
}

const originalLoad = Module._load;
Module._load = function load(request, parent, isMain) {
  if (request === 'better-sqlite3') return Database;
  return originalLoad.call(this, request, parent, isMain);
};

// Worker threads (sqlite-writer.js, process-telemetry-worker.js) load the
// same native module; make sure they preload this shim too.
try {
  const workerThreads = require('node:worker_threads');
  const OriginalWorker = workerThreads.Worker;
  if (typeof OriginalWorker === 'function' && !OriginalWorker.__owlSqliteShim) {
    const WrappedWorker = class OwlSqliteWorker extends OriginalWorker {
      constructor(filename, options = {}) {
        const execArgv = Array.isArray(options.execArgv) ? options.execArgv.slice() : [];
        if (!execArgv.includes(__filename)) execArgv.push('--require', __filename);
        super(filename, { ...options, execArgv });
      }
    };
    WrappedWorker.__owlSqliteShim = true;
    workerThreads.Worker = WrappedWorker;
  }
} catch {
  // worker_threads is always present in the main and utility processes; a
  // failure here only means workers keep the original module.
}

try {
  const { utilityProcess } = require('electron');
  if (utilityProcess && typeof utilityProcess.fork === 'function' && !utilityProcess.fork.__owlSqliteShim) {
    const fork = utilityProcess.fork.bind(utilityProcess);
    // utilityProcess ignores execArgv/NODE_OPTIONS on OHOS, so fork a small
    // entry that preloads this shim and then runs the real vendor entry.
    const wrapped = function owlSqliteFork(modulePath, args, options = {}) {
      const entry = require('node:path').join(__dirname, 'owl-utility-entry.cjs');
      return fork(entry, ['--owl-real-entry=' + modulePath, ...(args || [])], options);
    };
    wrapped.__owlSqliteShim = true;
    utilityProcess.fork = wrapped;
  }
} catch {
  // Renderer/worker contexts have no electron module; nothing to patch.
}

console.log('OWL_SQLITE shim active');
