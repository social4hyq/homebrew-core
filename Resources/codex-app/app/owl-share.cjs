'use strict';

// Letting the desktop app and the terminal share one `codex app-server`. The server
// listens on a loopback WebSocket with a capability token and is registered in
// ~/.config/codex-app/server.json. `codex-app serve` starts it from a terminal;
// without one the app's own spawn goes through owl-codex-bridge.cjs, which
// attaches to a registered server or starts one (it then ends with the app, and
// a terminal can use it meanwhile). When no server can be had the bridge starts a
// private codex as before.
//
// Nothing here needs Electron, so it is unit tested on its own.
const crypto = require('node:crypto');
const path = require('node:path');

const DEFAULT_PORT = 14288;
const ENDPOINT_RELATIVE = path.join('.config', 'codex-app', 'server.json');

function endpointFile(home) {
  return path.join(home, ENDPOINT_RELATIVE);
}

// The desktop starts the server as
//   codex -c features.code_mode_host=true app-server [-c k=v ...] --analytics-default-enabled
// Anything else (daemon, proxy, --listen, generate-*, ...) is not that spawn.
function isDesktopAppServerArgs(args) {
  if (!Array.isArray(args) || args.some((value) => typeof value !== 'string')) return false;
  let seen = false;
  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];
    if (arg === '-c' || arg === '--config' || arg === '--enable' || arg === '--disable') {
      if (index + 1 >= args.length) return false;
      index += 1;
    } else if (arg === 'app-server' && !seen) {
      seen = true;
    } else if (arg === '--analytics-default-enabled' && seen) {
      // the only flag the desktop adds after the subcommand
    } else {
      return false;
    }
  }
  return seen;
}

// {port, tokenFile, owner, pid} from the endpoint file, or null when it is missing
// or not usable. owner is 'app' for a server the bridge started, else 'terminal'.
function readEndpoint(file, fs) {
  let data;
  try {
    data = JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch {
    return null;
  }
  if (!data || data.version !== 1) return null;
  if (!Number.isInteger(data.port) || data.port < 1 || data.port > 65535) return null;
  if (typeof data.tokenFile !== 'string' || !path.isAbsolute(data.tokenFile)) return null;
  return {
    port: data.port,
    tokenFile: data.tokenFile,
    owner: data.owner === 'app' ? 'app' : 'terminal',
    pid: Number.isInteger(data.pid) ? data.pid : null,
  };
}

// The server this app started and that is still running, or null.
function appOwnedServer(file, fs, isAlive = processAlive) {
  const endpoint = readEndpoint(file, fs);
  return endpoint && endpoint.owner === 'app' && endpoint.pid && isAlive(endpoint.pid) ? endpoint : null;
}

function processAlive(pid) {
  try {
    process.kill(pid, 0);
    return true;
  } catch (error) {
    return error.code === 'EPERM';
  }
}

// Replacement spawn for an app-server start, or null to keep the original one.
//   args       the arguments of the spawn
//   hostNode   absolute path of the host node, or null
//   bridge     absolute path of owl-codex-bridge.cjs
//   endpoint   path of server.json
//   codexCli   host codex the bridge starts when it cannot attach
// Whether a server is registered is the bridge's business: it attaches to one,
// starts one, or falls back to a private codex.
function planRedirect({ name, args, hostNode, bridge, endpoint, codexCli }) {
  if (name !== 'spawn' || !hostNode || !isDesktopAppServerArgs(args)) return null;
  return {
    command: hostNode,
    args: [bridge, '--endpoint', endpoint, '--codex', codexCli, '--', ...args],
  };
}

// The desktop's app-server arguments with the WebSocket listener added, so a
// server the bridge starts runs the way the app would have run its own.
function listenArgs(args, { port, tokenFile }) {
  const at = args.indexOf('app-server');
  return [
    ...args.slice(0, at + 1),
    '--listen', `ws://127.0.0.1:${port}`, '--ws-auth', 'capability-token', '--ws-token-file', tokenFile,
    ...args.slice(at + 1),
  ];
}

// The capability token, created once with the owner-only mode.
function ensureToken(tokenFile, fs) {
  try {
    if (fs.readFileSync(tokenFile, 'utf8').trim()) return;
  } catch {
    // Not created yet.
  }
  fs.mkdirSync(path.dirname(tokenFile), { recursive: true });
  fs.writeFileSync(tokenFile, crypto.randomBytes(24).toString('hex'), { mode: 0o600 });
  fs.chmodSync(tokenFile, 0o600);
}

function ready(port, http) {
  return new Promise((resolve) => {
    const request = http.get({ host: '127.0.0.1', port, path: '/readyz', timeout: 1500 }, (response) => {
      response.resume();
      resolve(response.statusCode === 200);
    });
    request.on('timeout', () => request.destroy());
    request.on('error', () => resolve(false));
  });
}

function freePort(net) {
  return new Promise((resolve, reject) => {
    const server = net.createServer();
    server.once('error', reject);
    server.listen(0, '127.0.0.1', () => { const { port } = server.address(); server.close(() => resolve(port)); });
  });
}

// Start the shared server for the app and register it. Tries the usual port first,
// then any free one. Returns {port, tokenFile, child, stop} or null.
//   deps  { fs, childProcess, http, net, env, log, readyTimeoutMs }
async function startSharedServer({ codex, args, endpoint, defaultPort }, deps) {
  const { fs, childProcess, http, net, env, log = () => {}, readyTimeoutMs = 30000 } = deps;
  const dir = path.dirname(endpoint);
  const tokenFile = path.join(dir, 'ws-token');
  try {
    ensureToken(tokenFile, fs);
  } catch (error) {
    log('no token (' + error.message + ')');
    return null;
  }
  const logFile = path.join(dir, 'server.log');
  for (const wanted of [defaultPort || DEFAULT_PORT, 0]) {
    let port = wanted;
    try {
      if (!port) port = await freePort(net);
    } catch {
      return null;
    }
    let out;
    try {
      out = fs.openSync(logFile, 'a', 0o600);
    } catch {
      out = 'ignore';
    }
    let exited = false;
    const child = childProcess.spawn(codex, listenArgs(args, { port, tokenFile }), {
      stdio: ['ignore', out, out],
      env,
    });
    if (typeof out === 'number') fs.closeSync(out);
    child.once('error', () => { exited = true; });
    child.once('exit', () => { exited = true; });
    const deadline = Date.now() + readyTimeoutMs;
    let up = false;
    while (!exited && Date.now() < deadline) {
      if (await ready(port, http)) { up = true; break; }
      await new Promise((resolve) => setTimeout(resolve, 150));
    }
    if (!up) {
      try { child.kill(); } catch {}
      log('the server did not start on port ' + port);
      continue;
    }
    try {
      fs.writeFileSync(endpoint, JSON.stringify({
        version: 1, port, tokenFile, pid: child.pid, owner: 'app', ownerPid: process.pid, started: new Date().toISOString(),
      }) + '\n', { mode: 0o600 });
    } catch (error) {
      log('could not register the server (' + error.message + ')');
      try { child.kill(); } catch {}
      return null;
    }
    const stop = () => {
      try { child.kill(); } catch {}
      try {
        if (JSON.parse(fs.readFileSync(endpoint, 'utf8')).pid === child.pid) fs.unlinkSync(endpoint);
      } catch {
        // Already gone, or someone else's now.
      }
    };
    return { port, tokenFile, child, stop };
  }
  return null;
}

module.exports = {
  appOwnedServer, endpointFile, ensureToken, isDesktopAppServerArgs, listenArgs, planRedirect, processAlive, readEndpoint,
  startSharedServer,
};
