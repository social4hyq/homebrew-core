#!/usr/bin/env bash
# genoffice-app: install, start and read back the GenOffice runtime probe HAP.
set -euo pipefail

BUNDLE_ID="com.social4hyq.genoffice"
MODULE="electron"
ABILITY="EntryAbility"
REPORT_PORT="${GENOFFICE_DESKTOP_REPORT_PORT:-18765}"
STATE_DIR="${HOME:?HOME must be set}/.config/genoffice-app"

usage() {
  cat <<'EOF'
Usage: genoffice-app <command>

Commands:
  install   Sign and install the probe HAP (needs hdc and an unlocked device)
  start     Open the app on the device
  probe     Listen on loopback for the report the app sends, print it and keep
            it under ~/.config/genoffice-app (run this before `start`)
  -h, --help  Show this help
EOF
}

cmd_start() {
  local hdc="${GENOFFICE_DESKTOP_HDC:-${GENOFFICE_DESKTOP_HDC_DEFAULT:-hdc}}"
  if ! command -v "$hdc" >/dev/null 2>&1; then
    printf 'genoffice-app: hdc not found; install ohos-sdk-toolchains\n' >&2
    exit 1
  fi
  "$hdc" shell aa start -a "$ABILITY" -b "$BUNDLE_ID" -m "$MODULE" >/dev/null
}

cmd_probe() {
  mkdir -p "$STATE_DIR"
  exec node - "$REPORT_PORT" "$STATE_DIR" <<'JS'
const http = require("node:http");
const fs = require("node:fs");
const path = require("node:path");
const [port, dir] = process.argv.slice(2);
const seen = new Set();
const server = http.createServer((request, response) => {
  let body = "";
  request.on("data", chunk => { body += chunk; });
  request.on("end", () => {
    response.writeHead(204);
    response.end();
    const kind = request.url.slice(1).replace(/[^a-z]/g, "") || "unknown";
    try {
      const text = JSON.stringify(JSON.parse(body), null, 2);
      fs.writeFileSync(path.join(dir, `probe-${kind}.json`), `${text}\n`);
      console.log(`== ${kind}\n${text}`);
    } catch {
      console.log(`== ${kind} (not json)\n${body.slice(0, 2000)}`);
    }
    seen.add(kind);
    if (seen.has("main") && seen.has("renderer")) setTimeout(() => server.close(), 200);
  });
});
const timer = setTimeout(() => process.exit(seen.size ? 0 : 1), 300000);
server.on("close", () => clearTimeout(timer));
server.listen(Number(port), "127.0.0.1", () => console.error(`listening on 127.0.0.1:${port}`));
JS
}

cmd_install() {
  : "${GENOFFICE_DESKTOP_INSTALL_SCRIPT:?genoffice-app formula did not set the install script path}"
  exec bash "$GENOFFICE_DESKTOP_INSTALL_SCRIPT" "$@"
}

case "${1:-}" in
  start) shift; cmd_start "$@" ;;
  probe) shift; cmd_probe "$@" ;;
  install) shift; cmd_install "$@" ;;
  -h | --help | help) usage ;;
  *) usage >&2; exit 2 ;;
esac
