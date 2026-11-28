#!/usr/bin/env node
// Check that a rendered waiting.html uses well-formed commands.
//
//   check-waiting-commands.cjs STRINGS.json RENDERED.html
//
// {{command}} in the shared template is the complete `ohos-app install <id>`
// command from an app's waiting.json. The template must use it as-is for the
// install state and derive `ohos-app status <id>` / `ohos-app start <id>` for
// the diagnostic states — never append install/status/serve to the full
// install command (which used to produce `... install opencode-desktop install`).
"use strict";
const fs = require("node:fs");
const [stringsPath, htmlPath] = process.argv.slice(2);
if (!stringsPath || !htmlPath) {
  process.stderr.write("usage: check-waiting-commands.cjs STRINGS.json RENDERED.html\n");
  process.exit(2);
}
const strings = JSON.parse(fs.readFileSync(stringsPath, "utf8"));
const html = fs.readFileSync(htmlPath, "utf8");
const cmd = strings.command; // ohos-app install <id>
const broken = [`${cmd} install`, `${cmd} status`, `${cmd} serve`];
const hasBroken = broken.some((b) => html.includes(b));
const hasInstall = html.includes(`'${cmd}'`); // const installCmd = '<full command>';
const hasStatus = html.includes("'ohos-app status '"); // built from app id
const hasStart = html.includes("'ohos-app start '"); // built from app id
if (!hasBroken && hasInstall && hasStatus && hasStart) {
  process.stdout.write("commands well-formed\n");
} else {
  process.stderr.write(
    `bad commands: hasBroken=${hasBroken} hasInstall=${hasInstall} ` +
      `hasStatus=${hasStatus} hasStart=${hasStart}\n`,
  );
  process.exit(1);
}
