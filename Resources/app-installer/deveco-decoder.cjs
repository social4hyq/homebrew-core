"use strict";

const fs = require("node:fs");
const path = require("node:path");
const crypto = require("node:crypto");
const vm = require("node:vm");

function extractDecoderClass(source) {
  const method = source.indexOf("static decryptPwd(");
  if (method < 0) throw new Error("DevEco CLI signing decoder is missing; refusing to guess");
  const assignment = /\b(?:var|let|const)\s+[A-Za-z_$][\w$]*\s*=\s*class\b/g;
  let match;
  let start = -1;
  while ((match = assignment.exec(source)) && match.index < method) start = match.index + match[0].lastIndexOf("class");
  if (start < 0) throw new Error("DevEco CLI decoder layout changed; refusing to guess");

  const opening = source.indexOf("{", start);
  if (opening < 0 || opening > method) throw new Error("cannot locate DevEco CLI decoder class body");
  let depth = 0;
  let state = "code";
  let escaped = false;
  let regexClass = false;
  let regexMayStart = true;
  for (let i = opening; i < source.length; i += 1) {
    const c = source[i];
    const next = source[i + 1];
    if (state === "line-comment") {
      if (c === "\n") state = "code";
      continue;
    }
    if (state === "block-comment") {
      if (c === "*" && next === "/") { state = "code"; i += 1; }
      continue;
    }
    if (state === "single" || state === "double" || state === "template") {
      if (escaped) { escaped = false; continue; }
      if (c === "\\") { escaped = true; continue; }
      if ((state === "single" && c === "'") || (state === "double" && c === '"') || (state === "template" && c === "`")) {
        state = "code";
        regexMayStart = false;
      }
      continue;
    }
    if (state === "regex") {
      if (escaped) { escaped = false; continue; }
      if (c === "\\") { escaped = true; continue; }
      if (c === "[") regexClass = true;
      else if (c === "]") regexClass = false;
      else if (c === "/" && !regexClass) { state = "code"; regexMayStart = false; }
      continue;
    }
    if (c === "/" && next === "/") { state = "line-comment"; i += 1; continue; }
    if (c === "/" && next === "*") { state = "block-comment"; i += 1; continue; }
    if (c === "'") { state = "single"; continue; }
    if (c === '"') { state = "double"; continue; }
    if (c === "`") { state = "template"; continue; }
    if (c === "/" && regexMayStart) { state = "regex"; regexClass = false; continue; }
    if (c === "{") { depth += 1; regexMayStart = true; continue; }
    if (c === "}") {
      depth -= 1;
      if (depth === 0) {
        if (method > i) throw new Error("DevEco CLI decoder class does not contain decryptPwd; refusing to guess");
        return source.slice(start, i + 1);
      }
      regexMayStart = false;
      continue;
    }
    if (!/\s/.test(c)) regexMayStart = "=(:,[!&|?;".includes(c);
  }
  throw new Error("DevEco CLI decoder class is incomplete");
}

function decoderGlobals(decoderClass) {
  const alias = (label, pattern) => {
    const names = new Set([...decoderClass.matchAll(pattern)].map((found) => found[1]));
    if (names.size !== 1) throw new Error(`DevEco CLI decoder ${label} alias is ambiguous; refusing to guess`);
    return [...names][0];
  };
  return {
    [alias("path", /\b([A-Za-z_$][\w$]*)\.(?:resolve|join)\(/g)]: path,
    [alias("crypto", /\b([A-Za-z_$][\w$]*)\.(?:pbkdf2Sync|createDecipheriv)\(/g)]: crypto,
    [alias("fs", /\b([A-Za-z_$][\w$]*)\.(?:readdirSync|statSync|readFileSync)\(/g)]: fs,
    [alias("logger", /\b([A-Za-z_$][\w$]*)\(`\[DecipherUtil\]/g)]: () => {},
  };
}

function loadDecoder(cli) {
  const resolved = path.resolve(cli);
  const decoderClass = extractDecoderClass(fs.readFileSync(resolved, "utf8"));
  return vm.runInNewContext(`(${decoderClass})`, {
    Buffer, Int8Array, ...decoderGlobals(decoderClass),
  });
}

function cliVersion(cli) {
  try {
    return JSON.parse(fs.readFileSync(path.join(path.dirname(cli), "../package.json"), "utf8")).version || "unknown";
  } catch {
    return "unknown";
  }
}

function checkDecoder(cli) {
  const resolved = path.resolve(cli);
  loadDecoder(resolved);
  return { cli: resolved, version: cliVersion(resolved) };
}

function decodePasswords(cli, configDir, storePassword, keyPassword) {
  const decoder = loadDecoder(cli);
  const decodedStore = decoder.decryptPwd(configDir, storePassword, "storePassword");
  const decodedKey = decoder.decryptPwd(configDir, keyPassword, "keyPassword");
  if (typeof decodedStore !== "string" || typeof decodedKey !== "string") {
    throw new Error("DevEco CLI did not decode signing passwords");
  }
  return { storePassword: decodedStore, keyPassword: decodedKey };
}

module.exports = { checkDecoder, decodePasswords };
