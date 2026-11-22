'use strict';

// Decisions for letting the desktop app share one `codex app-server` with the
// terminal. `codex-app serve` starts a server on a loopback WebSocket and writes
// where it is to ~/.config/codex-app/server.json. When that file exists the
// shim runs the app's app-server spawn through owl-codex-bridge.cjs, which
// attaches to the server (and starts a private codex itself when it cannot).
//
// Nothing here needs Electron, so it is unit tested on its own.
const path = require('node:path');

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

// {port, tokenFile} from the endpoint file, or null when it is missing or not usable.
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
  return { port: data.port, tokenFile: data.tokenFile };
}

// Replacement spawn for an app-server start, or null to keep the original one.
//   args       the arguments of the spawn
//   hostNode   absolute path of the host node, or null
//   bridge     absolute path of owl-codex-bridge.cjs
//   endpoint   path of server.json
//   codexCli   host codex the bridge starts when it cannot attach
function planRedirect({ name, args, hostNode, bridge, endpoint, codexCli, fs }) {
  if (name !== 'spawn' || !hostNode || !isDesktopAppServerArgs(args)) return null;
  if (!readEndpoint(endpoint, fs)) return null;
  return {
    command: hostNode,
    args: [bridge, '--endpoint', endpoint, '--codex', codexCli, '--', ...args],
  };
}

module.exports = { endpointFile, isDesktopAppServerArgs, planRedirect, readEndpoint };
