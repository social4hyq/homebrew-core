// A stand-in for the magpie binary, run by bun:
//   fake-magpie.js web [--addr HOST:PORT] [--no-open]   a page that signs in with the key
//   fake-magpie.js <anything else>                      prints its arguments
// FAKE_MAGPIE_LOG gets one JSON line per start. FAKE_LINK_HOST / FAKE_LINK_SCHEME change
// the printed link, FAKE_COLOR wraps it in colour codes, FAKE_EXIT makes it exit with that
// code right after printing.
import { appendFileSync } from "node:fs";
import { createServer } from "node:http";
import { randomBytes } from "node:crypto";

const args = process.argv.slice(2);
if (process.env.FAKE_MAGPIE_LOG) appendFileSync(process.env.FAKE_MAGPIE_LOG, JSON.stringify(args) + "\n");
if (args[0] !== "web") {
  console.log("fake-magpie " + args.join(" "));
  process.exit(Number(process.env.FAKE_EXIT || 0));
}
const key = process.env.MAGPIE_WEB_KEY || randomBytes(32).toString("hex");
const addr = args.includes("--addr") ? args[args.indexOf("--addr") + 1] : "127.0.0.1:3430";
const [host, port] = addr.split(":");
const server = createServer((request, response) => {
  const ok = new URL(request.url, "http://x").searchParams.get("k") === key;
  response.writeHead(ok ? 303 : 401, { location: "/" });
  response.end();
});
server.listen(Number(port), host, () => {
  const link = `${process.env.FAKE_LINK_SCHEME || "http"}://${process.env.FAKE_LINK_HOST || host}:${port}/?k=${key}`;
  const text = `● magpie web on ${link}`;
  console.log(process.env.FAKE_COLOR ? `\x1b[32m${text}\x1b[0m` : text);
  console.log("  the link carries this run's key · Ctrl-C to stop");
  if (process.env.FAKE_EXIT) process.exit(Number(process.env.FAKE_EXIT));
});
process.on("SIGTERM", () => process.exit(0));
process.on("SIGINT", () => process.exit(0));
