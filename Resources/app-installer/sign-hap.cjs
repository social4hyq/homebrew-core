#!/usr/bin/env node
"use strict";

// Sign an already-built HAP with DevEco CLI-generated local material.
// No credential or decoded password is written to disk or emitted in output.

const fs = require("node:fs");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const devecoDecoder = require(path.join(__dirname, "deveco-decoder.cjs"));

function fail(message) {
  process.stderr.write(`app-installer-sign: ${message}\n`);
  process.exit(1);
}

function usage() {
  process.stdout.write(`Usage: sign-hap.cjs --hap <unsigned.hap> --profile <build-profile.json5> [options]\n` +
    `       sign-hap.cjs --check-decoder [--cli <cli.js>]\n\n` +
    `Options:\n  --output <signed.hap>  Output path (default: <input>-signed.hap)\n` +
    `  --cli <cli.js>         DevEco CLI bundle (or DEVECO_CLI_JS)\n` +
    `  --config-dir <path>    DevEco credential directory (default: ~/.ohos/config)\n` +
    `  --tool <path>          hap-sign-tool binary or jar (or HAP_SIGN_TOOL)\n\n` +
    `Your own signing material (replaces --profile; no DevEco login or CLI needed):\n` +
    `  --keystore <p12> --cert <cer/pem> --profile-file <p7b> --key-alias <alias>\n` +
    `  [--sign-alg <alg>]     default SHA256withECDSA\n` +
    `  [--keystore-pwd-env <VAR>] [--key-pwd-env <VAR>]\n` +
    `                         environment variables holding the passwords\n` +
    `                         (default APP_INSTALLER_KEYSTORE_PWD / APP_INSTALLER_KEY_PWD;\n` +
    `                         the key password falls back to the keystore password)\n\n` +
    `Security note: the signing tool receives decoded passwords in argv; they are\n` +
    `not logged or stored, but may briefly be visible to processes of the same user.\n`);
}

function parseArgs(args) {
  const opts = {};
  for (let i = 0; i < args.length; i += 1) {
    const key = args[i];
    if (key === "--help" || key === "-h") return { help: true };
    if (!["--hap", "--profile", "--output", "--cli", "--config-dir", "--tool", "--keystore", "--cert",
      "--profile-file", "--key-alias", "--sign-alg", "--keystore-pwd-env", "--key-pwd-env"].includes(key)) {
      fail(`unknown option: ${key}`);
    }
    const value = args[++i];
    if (!value || value.startsWith("--")) fail(`missing value for ${key}`);
    opts[key.slice(2).replaceAll("-", "_")] = value;
  }
  if (!opts.hap) fail("--hap is required");
  if (opts.keystore) {
    if (opts.profile) fail("--profile and --keystore are mutually exclusive");
    for (const key of ["cert", "profile_file", "key_alias"]) {
      if (!opts[key]) fail(`--${key.replaceAll("_", "-")} is required with --keystore`);
    }
  } else if (!opts.profile) {
    fail("--profile is required");
  }
  return opts;
}

function findCli(explicit) {
  const candidates = [explicit, process.env.DEVECO_CLI_JS].filter(Boolean);
  if (process.env.COMMAND_LINE_TOOL_PATH) {
    candidates.push(path.join(process.env.COMMAND_LINE_TOOL_PATH, "node_modules/@deveco/deveco-cli-openharmony-arm64/dist/cli.js"));
  }
  if (process.env.DEVECO_CLI_HOME) {
    candidates.push(path.join(process.env.DEVECO_CLI_HOME, "node_modules/@deveco/deveco-cli-openharmony-arm64/dist/cli.js"));
  }
  const npm = spawnSync("npm", ["root", "-g"], { encoding: "utf8", timeout: 10000 });
  if (npm.status === 0) {
    const root = npm.stdout.trim();
    candidates.push(path.join(root, "@deveco/deveco-cli-openharmony-arm64/dist/cli.js"));
    candidates.push(path.join(root, "@deveco/deveco-cli/cli.js"));
  }
  const cli = candidates.find((candidate) => candidate && fs.existsSync(candidate));
  if (!cli) fail("cannot find DevEco CLI; set --cli or DEVECO_CLI_JS");
  return path.resolve(cli);
}

function readJson5(profilePath, cliPath) {
  const req = require("node:module").createRequire(cliPath);
  try {
    return req("json5").parse(fs.readFileSync(profilePath, "utf8"));
  } catch (error) {
    if (error.code !== "MODULE_NOT_FOUND") throw error;
    try {
      return JSON.parse(fs.readFileSync(profilePath, "utf8"));
    } catch (parseError) {
      fail(`cannot parse signing profile JSON5: ${parseError.message}`);
    }
  }
}

function resolveTool(explicit) {
  const candidates = [explicit, process.env.HAP_SIGN_TOOL].filter(Boolean);
  for (const root of [process.env.COMMAND_LINE_TOOL_PATH, process.env.DEVECO_SDK_HOME].filter(Boolean)) {
    candidates.push(path.join(root, "toolchains/lib/hap-sign-tool"));
    candidates.push(path.join(root, "sdk/default/openharmony/toolchains/lib/hap-sign-tool"));
    candidates.push(path.join(root, "sdk/default/openharmony/toolchains/lib/hap-sign-tool.jar"));
  }
  const which = spawnSync("which", ["hap-sign-tool"], { encoding: "utf8", timeout: 10000 });
  if (which.status === 0) candidates.push(which.stdout.trim());
  const tool = candidates.find((candidate) => candidate && fs.existsSync(candidate));
  if (!tool) fail("cannot find hap-sign-tool; set --tool or HAP_SIGN_TOOL");
  return path.resolve(tool);
}

// Signing material supplied by the user (e.g. an AGC release certificate):
// no DevEco CLI and no decoding; passwords come from environment variables.
function ownMaterial(opts) {
  const material = {
    certpath: path.resolve(opts.cert), profile: path.resolve(opts.profile_file),
    storeFile: path.resolve(opts.keystore), keyAlias: opts.key_alias,
    signAlg: opts.sign_alg || "SHA256withECDSA",
  };
  for (const key of ["certpath", "profile", "storeFile"]) {
    if (!fs.existsSync(material[key]) || !fs.statSync(material[key]).isFile()) fail(`signing material file not found: ${material[key]}`);
  }
  const storeVar = opts.keystore_pwd_env || "APP_INSTALLER_KEYSTORE_PWD";
  const keyVar = opts.key_pwd_env || "APP_INSTALLER_KEY_PWD";
  const storePassword = process.env[storeVar];
  if (!storePassword) fail(`keystore password not found in environment variable ${storeVar}`);
  return { material, storePassword, keyPassword: process.env[keyVar] || storePassword };
}

// Signing material generated by `devecocli signature generate`, with the
// passwords decoded the way the DevEco CLI itself does.
function devecoMaterial(opts) {
  const profilePath = path.resolve(opts.profile);
  if (!fs.existsSync(profilePath) || !fs.statSync(profilePath).isFile()) fail(`file not found: ${profilePath}`);
  const cli = findCli(opts.cli);
  const profile = readJson5(profilePath, cli);
  const signing = profile.app?.signingConfigs?.find((item) => item.name === "default") || profile.app?.signingConfigs?.[0];
  const material = signing?.material;
  if (!material) fail("profile has no app.signingConfigs[].material; run devecocli signature generate in this project");
  for (const key of ["certpath", "profile", "storeFile", "keyAlias", "keyPassword", "storePassword", "signAlg"]) {
    if (!material[key]) fail(`signing material is missing ${key}`);
  }
  for (const key of ["certpath", "profile", "storeFile"]) {
    const file = path.isAbsolute(material[key]) ? material[key] : path.resolve(path.dirname(profilePath), material[key]);
    material[key] = file;
    if (!fs.existsSync(file)) fail(`signing material file not found: ${file}`);
  }

  const configDir = path.resolve(opts.config_dir || path.join(process.env.HOME || "", ".ohos/config"));
  try {
    const passwords = devecoDecoder.decodePasswords(cli, configDir, material.storePassword, material.keyPassword);
    return { material, ...passwords };
  } catch (error) {
    fail(error.message);
  }
}

function checkDecoder(args) {
  let cli;
  for (let i = 0; i < args.length; i += 1) {
    if (args[i] === "--help" || args[i] === "-h") { usage(); return; }
    if (args[i] !== "--cli") fail(`unknown option for --check-decoder: ${args[i]}`);
    cli = args[++i];
    if (!cli || cli.startsWith("--")) fail("missing value for --cli");
  }
  try {
    const result = devecoDecoder.checkDecoder(findCli(cli));
    process.stdout.write(`DevEco CLI decoder compatible (version ${result.version}): ${result.cli}\n`);
  } catch (error) {
    fail(error.message);
  }
}

function main() {
  const argv = process.argv.slice(2);
  if (argv[0] === "--check-decoder") { checkDecoder(argv.slice(1)); return; }
  const opts = parseArgs(argv);
  if (opts.help) { usage(); return; }
  const hap = path.resolve(opts.hap);
  const output = path.resolve(opts.output || hap.replace(/\.hap$/i, "-signed.hap"));
  if (hap === output) fail("input and output HAP paths must differ");
  const { material, storePassword, keyPassword } = opts.keystore ? ownMaterial(opts) : devecoMaterial(opts);
  if (!fs.existsSync(hap) || !fs.statSync(hap).isFile()) fail(`file not found: ${hap}`);

  const tool = resolveTool(opts.tool);
  const javaJar = tool.endsWith(".jar");
  const command = javaJar ? "java" : tool;
  const prefix = javaJar ? ["-jar", tool] : [];
  const args = [...prefix, "sign-app", "-mode", "localSign", "-compatibleVersion", "26", "-signCode", "1",
    "-keyAlias", material.keyAlias, "-keyPwd", keyPassword, "-keystorePwd", storePassword,
    "-appCertFile", material.certpath, "-profileFile", material.profile,
    "-keystoreFile", material.storeFile, "-signAlg", material.signAlg,
    "-inFile", hap, "-outFile", output];
  const result = spawnSync(command, args, { encoding: "utf8", timeout: 120000, input: "" });
  let log = `${result.stdout || ""}${result.stderr || ""}`;
  for (const secret of [storePassword, keyPassword, material.storePassword, material.keyPassword]) {
    if (secret) log = log.split(secret).join("[redacted]");
  }
  process.stdout.write(log);
  if (result.error) fail(`signing tool could not run: ${result.error.message}`);
  if (result.status !== 0) fail(`hap-sign-tool exited with status ${result.status}`);
  if (!fs.existsSync(output) || fs.statSync(output).size === 0) fail("signing tool did not create the signed HAP");
  process.stdout.write(`Signed HAP: ${output}\n`);
}

if (require.main === module) main();
