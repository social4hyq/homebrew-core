'use strict'
// Runtime probe for the GenOffice desktop shell on electron-ohos.
//
// The real shell reads its modules, sidecar and CLI relative to
// process.resourcesPath and assumes app.isPackaged. This probe reports what
// electron-ohos actually provides, so the HAP layout can be decided from
// evidence: where the resource directories are, whether an executable embedded
// in the HAP can be spawned, and which file systems the app state lands on.
// Results go to the console, to userData/probe.json, to the window, and to a
// loopback listener on the host (`genoffice-app probe`).
const { app, BrowserWindow } = require('electron')
const fs = require('node:fs')
const http = require('node:http')
const net = require('node:net')
const path = require('node:path')
const { spawn } = require('node:child_process')

const REPORT_PORT = 18765

function safe(fn) {
  try {
    return fn()
  } catch (error) {
    return `ERR ${error.code || error.message}`
  }
}

const list = (dir) => safe(() => fs.readdirSync(dir).sort().slice(0, 60))

const stat = (file) =>
  safe(() => {
    const info = fs.statSync(file)
    return { size: info.size, mode: (info.mode & 0o777).toString(8) }
  })

const fsType = (dir) => safe(() => `0x${fs.statfsSync(dir).type.toString(16)}`)

function post(kind, payload) {
  return new Promise((resolve) => {
    const body = JSON.stringify(payload)
    const request = http.request(
      {
        host: '127.0.0.1',
        port: REPORT_PORT,
        path: `/${kind}`,
        method: 'POST',
        headers: { 'content-type': 'application/json', 'content-length': Buffer.byteLength(body) },
      },
      (response) => {
        response.resume()
        response.on('end', () => resolve('sent'))
      },
    )
    request.setTimeout(3000, () => request.destroy(new Error('timeout')))
    request.on('error', (error) => resolve(`ERR ${error.code || error.message}`))
    request.end(body)
  })
}

// Spawn the embedded executable and send it one request that fails cleanly: any
// JSON line back proves the process runs and speaks its protocol.
function probeSidecar(binary) {
  return new Promise((resolve) => {
    const result = { binary, stat: stat(binary) }
    let stdout = ''
    let stderr = ''
    let child
    try {
      child = spawn(binary, [], { stdio: ['pipe', 'pipe', 'pipe'] })
    } catch (error) {
      result.spawnThrew = error.code || error.message
      resolve(result)
      return
    }
    const timer = setTimeout(() => {
      result.timedOut = true
      child.kill('SIGKILL')
    }, 4000)
    child.stdin.on('error', () => {})
    child.on('error', (error) => {
      result.error = error.code || error.message
    })
    child.on('spawn', () => {
      result.spawned = true
      const request = { version: 1, requestId: 'probe', command: 'archive_manifest', path: '/nonexistent.xlsx' }
      child.stdin.write(`${JSON.stringify(request)}\n`)
    })
    child.stdout.on('data', (chunk) => {
      stdout += chunk
      if (stdout.includes('\n')) child.stdin.end()
    })
    child.stderr.on('data', (chunk) => {
      stderr += chunk
    })
    child.on('close', (code, signal) => {
      clearTimeout(timer)
      result.exit = { code, signal }
      result.stdout = stdout.slice(0, 300)
      result.stderr = stderr.slice(0, 300)
      resolve(result)
    })
  })
}

function probeSocket(file) {
  return new Promise((resolve) => {
    safe(() => fs.unlinkSync(file))
    const server = net.createServer()
    server.once('error', (error) => resolve({ file, error: error.code || error.message }))
    server.listen(file, () => {
      const mode = stat(file)
      server.close(() => resolve({ file, listened: true, mode }))
    })
  })
}

async function collect() {
  const appPath = app.getAppPath()
  const bases = [
    ...new Set([process.resourcesPath, appPath, path.dirname(appPath), path.dirname(path.dirname(appPath))]),
  ]
  const userData = app.getPath('userData')
  const temp = app.getPath('temp')
  const report = {
    app: {
      isPackaged: app.isPackaged,
      name: app.getName(),
      appPath,
      resourcesPath: process.resourcesPath,
      execPath: process.execPath,
      userData,
      temp,
      home: app.getPath('home'),
    },
    runtime: {
      platform: process.platform,
      arch: process.arch,
      uid: safe(() => process.getuid()),
      versions: process.versions,
    },
    layout: Object.fromEntries(
      bases.map((base) => [
        base,
        {
          list: list(base),
          marker: stat(path.join(base, 'probe-marker.txt')),
          sidecar: stat(path.join(base, 'native', 'xlsx-sidecar.bin')),
        },
      ]),
    ),
    fileSystems: { userData: fsType(userData), temp: fsType(temp) },
    sqlite: safe(() => typeof require('node:sqlite').DatabaseSync),
  }
  const sidecar = bases.map((base) => path.join(base, 'native', 'xlsx-sidecar.bin')).find((file) => fs.existsSync(file))
  report.sidecar = sidecar ? await probeSidecar(sidecar) : 'not found under any candidate base'
  report.sockets = {
    userData: await probeSocket(path.join(userData, 'probe.sock')),
    temp: await probeSocket(path.join(temp, 'probe.sock')),
  }
  return report
}

async function run(window) {
  const report = await collect()
  const text = JSON.stringify(report, null, 2)
  console.log(`genoffice-probe ${text}`)
  safe(() => fs.writeFileSync(path.join(app.getPath('userData'), 'probe.json'), `${text}\n`))
  report.reported = await post('main', report)
  await window.webContents.executeJavaScript(
    `document.getElementById('main').textContent = ${JSON.stringify(JSON.stringify(report, null, 2))}`,
  )
}

app.whenReady().then(() => {
  const window = new BrowserWindow({ width: 900, height: 700 })
  window.loadFile(path.join(__dirname, 'index.html'))
  window.webContents.once('did-finish-load', () => {
    run(window).catch((error) => console.log(`genoffice-probe failed ${error.stack || error}`))
  })
})

app.on('window-all-closed', () => app.quit())
