#!/usr/bin/env node
'use strict';
// Thin client for Obsidian's command line interface on HarmonyOS PC.
//
// The app listens on a UNIX socket inside its sandbox, which the host cannot
// reach. The HAP's host process bridges it to 127.0.0.1 with a token and writes
// {port, token, pid} to $HOME/.cache/obsidian-desktop/cli.json; this client
// speaks the same newline-delimited JSON protocol Obsidian's own CLI uses.

const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const net = require('node:net');

const configPath = path.join(os.homedir(), '.cache', 'obsidian-desktop', 'cli.json');
let config;
try {
  config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
} catch {
  process.stderr.write(
    `obsidian-desktop: no CLI endpoint at ${configPath}\n` +
    'Start the app first, and enable Settings -> General -> Command line interface.\n',
  );
  process.exit(1);
}

const argv = process.argv.slice(2);
const socket = net.connect(config.port, '127.0.0.1', () => {
  socket.write(`${config.token}\n`);
  socket.write(`${JSON.stringify({ argv, tty: Boolean(process.stdout.isTTY), cwd: process.cwd() })}\n`);
});

socket.on('error', (error) => {
  process.stderr.write(`obsidian-desktop: cannot reach the app (${error.message}); is it running?\n`);
  process.exit(1);
});

socket.pipe(process.stdout);
// Only forward stdin for interactive use; piping a closed stdin would end the
// socket before the request is written.
if (process.stdin.isTTY) process.stdin.pipe(socket);
socket.on('end', () => process.exit(0));
