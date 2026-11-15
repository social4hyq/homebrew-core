// dsh-desktop-bridge: host-side relay between the HAP Electron shell and a real
// upstream dsh-desktop-host process.
//
//   HAP shell ──TCP 127.0.0.1:BRIDGE_PORT (JSON lines)──► bridge ──Node IPC──► desktop-host
//
// Design: openspec/specs/dsh-desktop-ohos-port.md (§2). Key rules:
// - One shell connection at a time ("owned Host" semantics); a new connection
//   while one is active is refused with a bridge-error line (the shell's own
//   single-instance lock makes this a don't-care in practice).
// - Shell disconnect == app quit == graceful Host shutdown (upstream semantics:
//   Host lifetime follows the app run). No cross-restart reattach: the desktop
//   credential is generated per shell launch and cannot be re-bound.
// - Host stderr/stdout go to the log file, never onto the message channel
//   (the shell hard-fails on non-protocol IPC messages).

import { fork } from 'node:child_process'
import { createWriteStream, mkdirSync, writeFileSync, readFileSync, existsSync, rmSync } from 'node:fs'
import net from 'node:net'
import path from 'node:path'
import os from 'node:os'
import { pathToFileURL } from 'node:url'

const BRIDGE_PORT = Number(process.env.DSH_BRIDGE_PORT ?? 3090)
const BRIDGE_HOST = '127.0.0.1'

// Layout inside the formula keg (resolved relative to this file at libexec/):
//   libexec/runtime/               runtimeDir for desktop-host
//   libexec/runtime/primary-runtime/  (DSH_PRIMARY_RUNTIME; beside runtimeDir per upstream contract)
// projectDir (desktop profile + cwd) lives in the user's DSH home.
const LIBEXEC = process.env.DSH_BRIDGE_LIBEXEC ?? path.resolve(path.dirname(new URL(import.meta.url).pathname), '..')
// 安装布局：<libexec>/runtime/dsh（运行时树）与 <libexec>/runtime/primary-runtime 兄弟；
// 开发布局：<target>/dsh 与 <target>/runtime/primary-runtime——两种都可以直接跑。
const RUNTIME_DIR = process.env.DSH_DESKTOP_RUNTIME_DIR
  ?? (existsSync(path.join(LIBEXEC, 'runtime', 'dsh', 'node_modules')) ? path.join(LIBEXEC, 'runtime', 'dsh') : path.join(LIBEXEC, 'runtime'))
const HOST_ENTRY = path.join(RUNTIME_DIR, 'node_modules', '@deepseek-ai', 'dsh-desktop-host', 'lib', 'index.js')
const STATE_DIR = process.env.DSH_BRIDGE_STATE_DIR ?? path.join(os.homedir(), '.deepseek-harness-desktop')
const PROJECT_DIR = process.env.DSH_DESKTOP_PROJECT_DIR ?? path.join(STATE_DIR, 'desktop-project')
const LOG_FILE = path.join(STATE_DIR, 'bridge.log')
const PID_FILE = path.join(STATE_DIR, 'bridge.pid')
/** brew node by default; desktop-host needs --expose-internals (HMR plugin, same as upstream spawn). */
const NODE = process.env.DSH_BRIDGE_NODE ?? 'node'

mkdirSync(STATE_DIR, { recursive: true })
mkdirSync(PROJECT_DIR, { recursive: true })
const log = createWriteStream(LOG_FILE, { flags: 'a' })
const stamp = () => new Date().toISOString()
function blog(event, data) {
  log.write(JSON.stringify({ t: stamp(), event, ...data }) + '\n')
}

// --- single instance (pidfile; OHOS 下 ps 可见性受限，靠 kill(pid,0) 探活) ---
if (existsSync(PID_FILE)) {
  const old = Number(readFileSync(PID_FILE, 'utf8'))
  if (Number.isInteger(old) && old > 0) {
    try { process.kill(old, 0); console.error(`bridge already running (pid ${old})`); process.exit(0) } catch { /* stale */ }
  }
}
writeFileSync(PID_FILE, String(process.pid))
process.on('exit', () => { try { rmSync(PID_FILE) } catch { /* ignore */ } })

/** Spawn the real desktop-host under Node with the upstream argv contract. */
async function initProfileOnce() {
  if (existsSync(path.join(PROJECT_DIR, 'package.json'))) return
  // 与壳侧 DesktopProjectManager.applyRelease 的 createPluginProfile 等价：
  // initProfile(projectDir, PROFILE_TEMPLATES.web.bundles)（都来自 runtime 树里的包）。
  const appBoot = await import(pathToFileURL(path.join(RUNTIME_DIR, 'node_modules', '@deepseek-ai', 'dsh-app-boot', 'lib', 'index.js')).href)
  const bundles = await import(pathToFileURL(path.join(RUNTIME_DIR, 'node_modules', '@deepseek-ai', 'dsh-official-bundles', 'lib', 'index.js')).href)
  appBoot.initProfile(PROJECT_DIR, bundles.PROFILE_TEMPLATES.web.bundles)
  blog('profile-init', { projectDir: PROJECT_DIR })
}

function spawnHost() {
  const primaryRuntime = process.env.DSH_DESKTOP_PRIMARY_RUNTIME
    ?? (existsSync(path.join(RUNTIME_DIR, '..', 'runtime', 'primary-runtime'))
      ? path.join(RUNTIME_DIR, '..', 'runtime', 'primary-runtime')
      : path.join(RUNTIME_DIR, '..', 'primary-runtime'))
  const nodeBin = path.join(path.dirname(primaryRuntime), 'bin')
  const child = fork(HOST_ENTRY, [
    RUNTIME_DIR,
    PROJECT_DIR,
    primaryRuntime,
    // packageManager：与上游 smoke 一致（pnpm 入口 + node 启动器目录）
    path.join(primaryRuntime, 'dependencies', 'pnpm', 'bin', 'pnpm.mjs'),
    nodeBin,
  ], {
    cwd: PROJECT_DIR,
    execPath: NODE,
    execArgv: ['--expose-internals'],
    silent: true,
    env: { ...process.env },
  })
  child.stdout?.on('data', (c) => log.write(`[host stdout ${stamp()}] ${String(c)}`))
  child.stderr?.on('data', (c) => log.write(`[host stderr ${stamp()}] ${String(c)}`))
  return child
}

let host // current desktop-host child
let hostState = 'absent' // absent | starting | ready | stopping
let shellSocket // current shell connection

function startHost() {
  blog('host-spawn', { entry: HOST_ENTRY })
  hostState = 'starting'
  const child = spawnHost()
  host = child
  child.on('message', (message) => {
    if (message?.type === 'ready') hostState = 'ready'
    // 透明中转：shell 侧自己做协议校验（isDesktopHostEvent）。
    if (host === child && shellSocket && !shellSocket.destroyed) shellSocket.write(JSON.stringify(message) + '\n')
  })
  child.on('exit', (code, signal) => {
    blog('host-exit', { code, signal })
    // 只处理当前代的退出：上一代 Host 的迟到的 exit 不得误伤新一代的连接。
    if (host === child) {
      hostState = 'absent'
      host = undefined
      // 让 shell 走它自己的 'close' 失败处理路径。
      if (shellSocket && !shellSocket.destroyed) shellSocket.end()
    }
  })
}

function stopHost() {
  if (host === undefined) return
  hostState = 'stopping'
  if (host.connected) host.send({ type: 'shutdown' }, () => {})
  const h = host
  setTimeout(() => { if (host === h && h.exitCode === null) h.kill('SIGTERM') }, 10_000).unref()
}

const server = net.createServer((socket) => {
  if (shellSocket !== undefined && !shellSocket.destroyed) {
    blog('shell-refused', { reason: 'already-connected' })
    socket.end()
    return
  }
  blog('shell-connected', {})
  shellSocket = socket
  let buffer = ''
  socket.on('data', (chunk) => {
    buffer += chunk.toString('utf8')
    for (;;) {
      const nl = buffer.indexOf('\n')
      if (nl < 0) break
      const line = buffer.slice(0, nl)
      buffer = buffer.slice(nl + 1)
      if (line.trim() === '') continue
      let message
      try { message = JSON.parse(line) } catch { blog('shell-bad-json', { line: line.slice(0, 200) }); continue }
      // bridge-* 消息由 bridge 本地处理，不转发给 Host（HAP 侧适配器的 kill 语义落在这里）。
      if (typeof message?.type === 'string' && message.type.startsWith('bridge-')) {
        if (message.type === 'bridge-kill' && host !== undefined) {
          blog('bridge-kill', { signal: message.signal })
          host.kill(typeof message.signal === 'string' ? message.signal : 'SIGTERM')
        }
        continue
      }
      if (host?.connected) host.send(message, () => {})
    }
  })
  socket.on('close', () => {
    // 只认当前 shell 的断开；被拒连接的 close 不得误伤在役会话。
    if (shellSocket === socket) {
      blog('shell-disconnected', {})
      shellSocket = undefined
      stopHost()
    }
  })
  socket.on('error', () => socket.destroy())
  void initProfileOnce()
    .catch((error) => blog('profile-init-failed', { error: String(error) }))
    .finally(() => startHost())
})

server.listen(BRIDGE_PORT, BRIDGE_HOST, () => {
  blog('bridge-listening', { port: BRIDGE_PORT, runtimeDir: RUNTIME_DIR })
  console.log(`dsh-desktop-bridge on ${BRIDGE_HOST}:${BRIDGE_PORT}`)
})

for (const sig of ['SIGINT', 'SIGTERM']) {
  process.on(sig, () => { stopHost(); server.close(); setTimeout(() => process.exit(0), 500).unref() })
}
