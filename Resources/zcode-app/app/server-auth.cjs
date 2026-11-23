'use strict';

// The host service (`zcode-app serve`) protects /api and /ws with a token that
// zcode-desktop.sh keeps in a 0600 file next to the credential secret. The shell
// reads that file, sends it as a Bearer header when probing the service and puts
// it in the first page URL, which makes the service set its own session cookie.

const path = require('node:path');

const TOKEN_RELATIVE_PATH = path.join('.zcode', 'v2', 'desktop-token');
// The wrapper writes 64 hex characters; anything that is not a plain token
// (empty, spaces, control characters) is treated as "no token yet".
const TOKEN_PATTERN = /^[A-Za-z0-9._~-]{16,256}$/;

// `host.home` is the HOME captured at install time (the shell's own HOME is the
// app sandbox), the same one the launcher gets.
function tokenFile(host, env) {
  const override = env && typeof env.ZCODE_DESKTOP_TOKEN_FILE === 'string' ? env.ZCODE_DESKTOP_TOKEN_FILE : '';
  if (override) return override;
  const home = host && typeof host.home === 'string' && host.home.length > 0
    ? host.home
    : (env && typeof env.HOME === 'string' ? env.HOME : '');
  return home ? path.join(home, TOKEN_RELATIVE_PATH) : '';
}

function readToken(fs, file) {
  if (!file) return '';
  let text;
  try {
    text = fs.readFileSync(file, 'utf8');
  } catch {
    return '';
  }
  const token = text.trim();
  return TOKEN_PATTERN.test(token) ? token : '';
}

function infoHeaders(token) {
  return token ? { Authorization: `Bearer ${token}` } : {};
}

// A usable service answers /api/server-info with 200 for our token and says it
// requires authentication. A server from before the token (authRequired false)
// or one that ignores it is not accepted: the shell then asks the launcher to
// start a protected one instead of attaching to an open loopback API.
function acceptServerInfo(statusCode, body) {
  if (statusCode !== 200) return false;
  try {
    return JSON.parse(body).authRequired === true;
  } catch {
    return false;
  }
}

// The token goes in the query only for the first page load; the service answers
// with an HttpOnly cookie, so /api and /ws need nothing else afterwards.
function authedUrl(origin, token) {
  return token ? `${origin}/?token=${encodeURIComponent(token)}` : `${origin}/`;
}

module.exports = { tokenFile, readToken, infoHeaders, acceptServerInfo, authedUrl, TOKEN_RELATIVE_PATH };
