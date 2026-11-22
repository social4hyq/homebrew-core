// Runs `magpie web` and records where it listens.
//
// magpie web takes a new key each run and only prints it in the link, so a program
// that wants to open the page has nothing to go on. This runs the real binary with
// its output passed through unchanged, and when the loopback link appears writes
//   ~/.config/magpie-app/web.json   {"version":1,"port":N,"pid":P}
//   ~/.config/magpie-app/web-key    the key of that link (mode 600)
// which the Magpie desktop app reads; it removes web.json when magpie web ends.
// Started with no options while a registered page still answers, it prints that
// page's link and does not start a second one.
//
//   MAGPIE_REAL  the real magpie binary
import { spawn } from "node:child_process";
import { chmodSync, mkdirSync, readFileSync, unlinkSync, writeFileSync } from "node:fs";
import { get } from "node:http";
import { join } from "node:path";
import { createInterface } from "node:readline";

const args = process.argv.slice(2);
const real = process.env.MAGPIE_REAL;
if (!real) {
  console.error("magpie: MAGPIE_REAL is not set");
  process.exit(2);
}
const directory = join(process.env.HOME || "", ".config", "magpie-app");
const registration = join(directory, "web.json");
const keyFile = join(directory, "web-key");
const KEY = /^[A-Za-z0-9._~-]{16,128}$/;
const LINK = /magpie web on (http:\/\/127\.0\.0\.1:([1-9]\d{0,4})\/\?k=([A-Za-z0-9._~-]{16,128}))\s*$/;

function readRegistered() {
  try {
    const port = Number(JSON.parse(readFileSync(registration, "utf8")).port);
    const key = readFileSync(keyFile, "utf8").trim();
    if (Number.isInteger(port) && port >= 1 && port <= 65535 && KEY.test(key)) return { port, key };
  } catch {
    // Nothing registered.
  }
  return null;
}

// True when the page answers to the key: it signs in with a redirect, a wrong key is 401.
function answers({ port, key }) {
  return new Promise((resolve) => {
    const request = get({ host: "127.0.0.1", port, path: `/?k=${encodeURIComponent(key)}`, timeout: 2000 }, (response) => {
      response.resume();
      resolve(response.statusCode === 303 || response.statusCode === 200);
    });
    request.on("timeout", () => request.destroy());
    request.on("error", () => resolve(false));
  });
}

function register(port, key) {
  try {
    mkdirSync(directory, { recursive: true, mode: 0o700 });
    chmodSync(directory, 0o700);
    writeFileSync(keyFile, key + "\n", { mode: 0o600 });
    chmodSync(keyFile, 0o600);
    writeFileSync(registration, JSON.stringify({ version: 1, port, pid: process.pid }) + "\n", { mode: 0o600 });
  } catch {
    // The page works unregistered.
  }
}

function unregister() {
  try {
    if (JSON.parse(readFileSync(registration, "utf8")).pid === process.pid) unlinkSync(registration);
  } catch {
    // Nothing of ours to remove.
  }
}

// With no options of its own (only --no-open) it would listen where the registered page
// already does, so show that one instead of starting another.
const plain = args.slice(1).every((arg) => arg === "--no-open");
if (plain) {
  const existing = readRegistered();
  if (existing && (await answers(existing))) {
    console.log(`magpie web is already running at http://127.0.0.1:${existing.port}/?k=${existing.key}`);
    process.exit(0);
  }
}

const child = spawn(real, args, { stdio: ["inherit", "pipe", "inherit"], env: process.env });
child.on("error", (error) => {
  console.error(`magpie: could not start ${real}: ${error.message}`);
  process.exit(127);
});
for (const signal of ["SIGINT", "SIGTERM", "SIGHUP"]) {
  process.on(signal, () => {
    try { child.kill(signal); } catch { /* already gone */ }
  });
}
const output = createInterface({ input: child.stdout });
output.on("line", (line) => {
  console.log(line);
  const match = LINK.exec(line.replace(/\x1b\[[0-9;]*m/g, ""));
  if (match && Number(match[2]) <= 65535) register(Number(match[2]), match[3]);
});
// Finish once the child has ended and its last lines are out.
let ended = null;
let drained = false;
function finish() {
  if (!ended || !drained) return;
  unregister();
  const { code, signal } = ended;
  process.exit(code === null ? (signal ? 128 + ({ SIGINT: 2, SIGTERM: 15, SIGHUP: 1 }[signal] || 1) : 1) : code);
}
child.on("exit", (code, signal) => { ended = { code, signal }; finish(); });
output.on("close", () => { drained = true; finish(); });
