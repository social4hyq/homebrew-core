#!/usr/bin/env node
// Render a waiting page from the shared template and one app's strings.
//
//   render-waiting.cjs TEMPLATE STRINGS.json OUTPUT
//
// TEMPLATE holds {{key}} placeholders. STRINGS.json is a flat object with one
// string per placeholder. The rendering is strict on purpose: a placeholder
// without a value, a value that no placeholder uses, and a value that could
// break out of the HTML text or the single-quoted JavaScript strings the
// template puts it in, are all errors, so a typo cannot ship a broken page.
// The output is written byte for byte as the template reads, with nothing
// added, so a template that reproduces an existing page can be checked by hash.
"use strict";
const fs = require("node:fs");

function fail(message) {
  process.stderr.write(`render-waiting: ${message}\n`);
  process.exit(1);
}

const [templatePath, stringsPath, outputPath] = process.argv.slice(2);
if (!templatePath || !stringsPath || !outputPath || process.argv.length > 5) {
  process.stderr.write("Usage: render-waiting.cjs TEMPLATE STRINGS.json OUTPUT\n");
  process.exit(2);
}

let values;
try {
  values = JSON.parse(fs.readFileSync(stringsPath, "utf8"));
} catch (error) {
  fail(`cannot read ${stringsPath}: ${error.message}`);
}
if (values === null || typeof values !== "object" || Array.isArray(values)) {
  fail(`${stringsPath} must be a JSON object`);
}
for (const [key, value] of Object.entries(values)) {
  if (typeof value !== "string" || value === "") fail(`${key}: must be a non-empty string`);
  if (/[<>&'"\\\r\n]|\{\{|\}\}/.test(value)) fail(`${key}: must not contain < > & ' " \\ a newline or a brace pair`);
}

let template;
try {
  template = fs.readFileSync(templatePath, "utf8");
} catch (error) {
  fail(`cannot read ${templatePath}: ${error.message}`);
}

// Every "{{" in the template must open a well-formed placeholder. (The page's
// own CSS and script contain "}}", so only the opening pair is checked.)
for (const match of template.matchAll(/\{\{(?![A-Za-z]+\}\})/g)) {
  const line = template.slice(0, match.index).split("\n").length;
  fail(`${templatePath}:${line}: malformed placeholder`);
}

const used = new Set();
const output = template.replace(/\{\{([A-Za-z]+)\}\}/g, (match, key) => {
  if (!Object.prototype.hasOwnProperty.call(values, key)) fail(`${stringsPath} has no value for {{${key}}}`);
  used.add(key);
  return values[key];
});
for (const key of Object.keys(values)) {
  if (!used.has(key)) fail(`${key} is in ${stringsPath} but the template does not use it`);
}

fs.writeFileSync(outputPath, output);
