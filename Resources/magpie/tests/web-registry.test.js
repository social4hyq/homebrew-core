// `magpie web` through the formula's wrapper, against a fake magpie.
import { afterEach, expect, test } from "bun:test";
import { spawn, spawnSync } from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { createServer } from "node:net";
import { tmpdir } from "node:os";
import { join } from "node:path";

const bun = process.execPath;
const wrapper = join(import.meta.dir, "..", "magpie.sh");
const fake = join(import.meta.dir, "fake-magpie.js");

const homes = [];
const running = [];
afterEach(() => {
  for (const child of running.splice(0)) child.kill("SIGTERM");
  for (const home of homes.splice(0)) rmSync(home, { recursive: true, force: true });
});

function setup() {
  const home = mkdtempSync(join(tmpdir(), "magpie-web-"));
  homes.push(home);
  const real = join(home, "magpie-real");
  writeFileSync(real, `#!/bin/sh\nexec "${bun}" "${fake}" "$@"\n`, { mode: 0o755 });
  const log = join(home, "starts.log");
  const env = { PATH: process.env.PATH, HOME: home, MAGPIE_REAL: real, MAGPIE_BUN: bun, FAKE_MAGPIE_LOG: log };
  return {
    home, env,
    registration: join(home, ".config/magpie-app/web.json"),
    keyFile: join(home, ".config/magpie-app/web-key"),
    starts: () => (existsSync(log) ? readFileSync(log, "utf8").trim().split("\n").map((line) => JSON.parse(line)) : []),
    run: (args, extra = {}) => spawnSync("sh", [wrapper, ...args], { encoding: "utf8", timeout: 20000, env: { ...env, ...extra } }),
    // magpie web stays in the foreground, like the real one.
    start: (args, extra = {}) => {
      const child = spawn("sh", [wrapper, ...args], { env: { ...env, ...extra }, stdio: ["ignore", "pipe", "pipe"] });
      running.push(child);
      let out = "";
      child.stdout.on("data", (chunk) => { out += chunk; });
      const exited = new Promise((resolve) => child.on("exit", (code, signal) => resolve({ code, signal })));
      return { child, exited, output: () => out };
    },
  };
}

async function until(check, what) {
  for (let i = 0; i < 100; i += 1) {
    const value = await check();
    if (value) return value;
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  throw new Error("timed out waiting for " + what);
}

function freePort() {
  return new Promise((resolve, reject) => {
    const server = createServer();
    server.listen(0, "127.0.0.1", () => { const { port } = server.address(); server.close(() => resolve(port)); });
    server.on("error", reject);
  });
}

const answers = (port, key) => fetch(`http://127.0.0.1:${port}/?k=${key}`, { redirect: "manual" }).then((r) => r.status, () => 0);
const link = (text) => /magpie web on (https?:\/\/\S+)/.exec(text)?.[1];

test("anything but web goes to the real binary untouched and registers nothing", () => {
  const ctx = setup();
  const result = ctx.run(["settings", "get", "lang"]);
  expect(result.stdout.trim()).toBe("fake-magpie settings get lang");
  expect(ctx.run(["ls"], { FAKE_EXIT: "3" }).status).toBe(3);
  expect(existsSync(join(ctx.home, ".config/magpie-app"))).toBe(false);
});

test("web passes the output through and records the port and the key of its link", async () => {
  const ctx = setup();
  const port = await freePort();
  const web = ctx.start(["web", "--addr", `127.0.0.1:${port}`, "--no-open"]);
  await until(() => existsSync(ctx.registration), "the registration");
  const printed = link(web.output());
  expect(printed).toMatch(new RegExp(`^http://127\\.0\\.0\\.1:${port}/\\?k=[0-9a-f]{64}$`));
  const key = new URL(printed).searchParams.get("k");
  expect(readFileSync(ctx.keyFile, "utf8").trim()).toBe(key);
  const data = JSON.parse(readFileSync(ctx.registration, "utf8"));
  expect(data.version).toBe(1);
  expect(data.port).toBe(port);
  expect(data.pid).toBeGreaterThan(0);
  expect(JSON.stringify(data)).not.toContain(key);
  expect(statSync(ctx.keyFile).mode & 0o777).toBe(0o600);
  expect(statSync(join(ctx.home, ".config/magpie-app")).mode & 0o777).toBe(0o700);
  expect(await until(() => answers(port, key), "the page")).toBe(303);
  expect(web.output()).toContain("the link carries this run's key");
  expect(ctx.starts()).toEqual([["web", "--addr", `127.0.0.1:${port}`, "--no-open"]]);
});

test("stopping web takes the registration away and keeps the key file", async () => {
  const ctx = setup();
  const port = await freePort();
  const web = ctx.start(["web", "--addr", `127.0.0.1:${port}`]);
  await until(() => existsSync(ctx.registration), "the registration");
  const key = readFileSync(ctx.keyFile, "utf8").trim();
  web.child.kill("SIGTERM");
  const { code } = await web.exited;
  expect(code).toBe(0);
  expect(existsSync(ctx.registration)).toBe(false);
  expect(existsSync(ctx.keyFile)).toBe(true);
  expect(await answers(port, key)).toBe(0);
});

test("the exit code of magpie web is the wrapper's", async () => {
  const ctx = setup();
  const port = await freePort();
  const web = ctx.start(["web", "--addr", `127.0.0.1:${port}`], { FAKE_EXIT: "7" });
  expect((await web.exited).code).toBe(7);
  expect(existsSync(ctx.registration)).toBe(false);
});

test("a second plain web shows the running page's link and starts nothing", async () => {
  const ctx = setup();
  const port = await freePort();
  const first = ctx.start(["web", "--addr", `127.0.0.1:${port}`]);
  await until(() => existsSync(ctx.registration), "the registration");
  const key = readFileSync(ctx.keyFile, "utf8").trim();
  await until(() => answers(port, key), "the page");
  for (const args of [["web"], ["web", "--no-open"]]) {
    const second = ctx.run(args);
    expect(second.status).toBe(0);
    expect(second.stdout).toContain(`magpie web is already running at http://127.0.0.1:${port}/?k=${key}`);
  }
  expect(ctx.starts().length).toBe(1);
  first.child.kill("SIGTERM");
});

test("web with options of its own always starts its own page", async () => {
  const ctx = setup();
  const one = await freePort();
  const first = ctx.start(["web", "--addr", `127.0.0.1:${one}`]);
  await until(() => existsSync(ctx.registration), "the registration");
  const two = await freePort();
  const second = ctx.start(["web", "--addr", `127.0.0.1:${two}`]);
  await until(() => ctx.starts().length === 2, "the second start");
  await until(() => JSON.parse(readFileSync(ctx.registration, "utf8")).port === two, "the second registration");
  first.child.kill("SIGTERM");
  await first.exited;
  expect(existsSync(ctx.registration)).toBe(true); // the second run's registration stays
  second.child.kill("SIGTERM");
  await second.exited;
  expect(existsSync(ctx.registration)).toBe(false);
});

test("a stale registration is replaced, and a registration the page refuses is not trusted", async () => {
  const ctx = setup();
  mkdirSync(join(ctx.home, ".config/magpie-app"), { recursive: true });
  writeFileSync(ctx.registration, JSON.stringify({ version: 1, port: await freePort(), pid: 1 }));
  writeFileSync(ctx.keyFile, "a".repeat(64));
  const port = await freePort();
  // Nothing answers on the stale port, so a plain web starts instead of reporting it.
  const web = ctx.start(["web", "--addr", `127.0.0.1:${port}`]);
  await until(() => ctx.starts().length === 1, "a start");
  await until(() => JSON.parse(readFileSync(ctx.registration, "utf8")).port === port, "the new registration");
  expect(readFileSync(ctx.keyFile, "utf8").trim()).not.toBe("a".repeat(64));
  web.child.kill("SIGTERM");
  await web.exited;
});

test("a registration the page refuses (wrong key) is not trusted either", async () => {
  const ctx = setup();
  const port = await freePort();
  const first = ctx.start(["web", "--addr", `127.0.0.1:${port}`]);
  await until(() => existsSync(ctx.registration), "the registration");
  writeFileSync(ctx.keyFile, "b".repeat(64));
  const second = ctx.run(["web", "--no-open"], { FAKE_EXIT: "5" });
  expect(second.stdout).not.toContain("already running");
  expect(second.status).toBe(5);
  first.child.kill("SIGTERM");
});

test("a link that is not loopback http is not registered", { timeout: 30000 }, async () => {
  for (const extra of [{ FAKE_LINK_HOST: "192.168.1.9" }, { FAKE_LINK_SCHEME: "https" }]) {
    const ctx = setup();
    const port = await freePort();
    const web = ctx.start(["web", "--addr", `127.0.0.1:${port}`], extra);
    await until(() => link(web.output()), "the link");
    await new Promise((resolve) => setTimeout(resolve, 400));
    expect(existsSync(ctx.registration)).toBe(false);
    expect(existsSync(ctx.keyFile)).toBe(false);
    web.child.kill("SIGTERM");
    await web.exited;
  }
});

test("a coloured link line and a key from MAGPIE_WEB_KEY are recorded", async () => {
  const ctx = setup();
  const port = await freePort();
  const key = "kept-key-1234567890-abc";
  const web = ctx.start(["web", "--addr", `127.0.0.1:${port}`], { FAKE_COLOR: "1", MAGPIE_WEB_KEY: key });
  await until(() => existsSync(ctx.registration), "the registration");
  expect(readFileSync(ctx.keyFile, "utf8").trim()).toBe(key);
  expect(await until(() => answers(port, key), "the page")).toBe(303);
  web.child.kill("SIGTERM");
});

test("a second run's registration is not removed by the first one ending", async () => {
  const ctx = setup();
  const port = await freePort();
  const first = ctx.start(["web", "--addr", `127.0.0.1:${port}`]);
  await until(() => existsSync(ctx.registration), "the registration");
  const pidOfFirst = JSON.parse(readFileSync(ctx.registration, "utf8")).pid;
  writeFileSync(ctx.registration, JSON.stringify({ version: 1, port: 1, pid: pidOfFirst + 100000 }));
  first.child.kill("SIGTERM");
  await first.exited;
  expect(JSON.parse(readFileSync(ctx.registration, "utf8")).pid).toBe(pidOfFirst + 100000);
});

test("without MAGPIE_REAL the web wrapper refuses to run", () => {
  const ctx = setup();
  const result = spawnSync("sh", [wrapper, "web"], { encoding: "utf8", env: { PATH: process.env.PATH, HOME: ctx.home, MAGPIE_BUN: bun } });
  expect(result.status).toBe(2);
  expect(result.stderr).toContain("MAGPIE_REAL is not set");
});
