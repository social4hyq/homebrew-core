"use strict";

// `magpie-app web` runs `magpie web` in a terminal with a key that stays the same
// (web-key) and writes where it listens (web.json) under the host home. The shell reads that
// file and, when the page answers to the key, opens it instead of starting a
// backend of its own, so the app and the terminal use one gateway and one page.
const { randomBytes } = require("node:crypto");
const fs = require("node:fs");
const http = require("node:http");
const { join } = require("node:path");

const KEY = /^[A-Za-z0-9._~-]{16,128}$/;
const DEFAULT_PORT = 3431;

function targetFile(home) {
  return join(home, ".config", "magpie-app", "web.json");
}

function keyFile(home) {
  return join(home, ".config", "magpie-app", "web-key");
}

// The registered page, or undefined when there is no usable registration.
function readTarget(home, fileSystem = fs) {
  if (typeof home !== "string" || !home) return;
  let data;
  let key;
  try {
    data = JSON.parse(fileSystem.readFileSync(targetFile(home), "utf8"));
    key = fileSystem.readFileSync(keyFile(home), "utf8").trim();
  } catch {
    return;
  }
  if (!data || !KEY.test(key)) return;
  const port = Number(data.port);
  if (!Number.isInteger(port) || port < 1 || port > 65535) return;
  return { url: new URL(`http://127.0.0.1:${port}/?k=${encodeURIComponent(key)}`) };
}

// The port to start on: where the last registration was, else the app's own default
// (3431, what `magpie-app web` uses too; a plain `magpie web` keeps 3430).
function preferredPort(home, fileSystem = fs) {
  try {
    const port = Number(JSON.parse(fileSystem.readFileSync(targetFile(home), "utf8")).port);
    if (Number.isInteger(port) && port >= 1 && port <= 65535) return port;
  } catch {
    // No registration yet.
  }
  return DEFAULT_PORT;
}

// The key that stays the same between runs, created on first use.
function ensureKey(home, fileSystem = fs) {
  try {
    const key = fileSystem.readFileSync(keyFile(home), "utf8").trim();
    if (KEY.test(key)) return key;
  } catch {
    // Not created yet.
  }
  const key = randomBytes(32).toString("hex");
  fileSystem.mkdirSync(join(home, ".config", "magpie-app"), { recursive: true, mode: 0o700 });
  fileSystem.writeFileSync(keyFile(home), key + "\n", { mode: 0o600 });
  return key;
}

// Tell the terminal where the shell's own backend listens, so `magpie-app web` there
// finds it instead of starting a second one.
function register(home, port, pid, fileSystem = fs) {
  fileSystem.writeFileSync(targetFile(home), JSON.stringify({ version: 1, port, pid }) + "\n", { mode: 0o600 });
}

// Remove the registration, but only the one this process wrote.
function unregister(home, pid, fileSystem = fs) {
  try {
    if (JSON.parse(fileSystem.readFileSync(targetFile(home), "utf8")).pid === pid) fileSystem.unlinkSync(targetFile(home));
  } catch {
    // Nothing of ours to remove.
  }
}

// True when a magpie web answers to the key: the page signs in with a redirect, a
// wrong or missing key is refused with 401.
function probe(target, { timeoutMs = 2000, client = http } = {}) {
  return new Promise((resolve) => {
    const request = client.get(target.url, { timeout: timeoutMs }, (response) => {
      response.resume();
      resolve(response.statusCode === 303 || response.statusCode === 200);
    });
    request.on("timeout", () => { request.destroy(); resolve(false); });
    request.on("error", () => resolve(false));
  });
}

module.exports = { DEFAULT_PORT, ensureKey, keyFile, preferredPort, probe, readTarget, register, targetFile, unregister };
