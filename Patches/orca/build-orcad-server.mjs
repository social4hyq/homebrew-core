// Build the Orca runtime server (orcad) for OpenHarmony from the upstream checkout.
//
// Mirrors config/scripts/orcad-distribution/server-bundle/build-orcad.mjs, but
// without its per-target prebuild and pinned-Node staging: upstream has no
// openharmony server target, so the formula supplies the two native addons it
// builds for OpenHarmony and the web client it builds with `pnpm build:web`.
//
// The OpenHarmony esbuild package is a WebAssembly shim (Go 1.25 green-tea GC
// included). Bundling everything in one long-lived process grew the wasm heap
// until the GC asserted ("steal with local work available"), so each entry is
// bundled by a fresh esbuild process and retried once.
//
// Environment:
//   ORCA_SRC      upstream checkout (the brew buildpath)
//   ORCA_OUT      output directory for the server bundle
//   ORCA_WEB      built web client (out/web)
//   ORCA_PTY      node-pty pty.node built for OpenHarmony
//   ORCA_WATCHER  @parcel/watcher watcher.node built for OpenHarmony
import { spawnSync } from 'node:child_process'
import { cpSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { createRequire } from 'node:module'
import { dirname, join } from 'node:path'

const ROOT = process.env.ORCA_SRC
const OUT = process.env.ORCA_OUT
const WEB = process.env.ORCA_WEB
const PTY = process.env.ORCA_PTY
const WATCHER = process.env.ORCA_WATCHER
if (!ROOT || !OUT || !WEB || !PTY || !WATCHER) {
  throw new Error('ORCA_SRC, ORCA_OUT, ORCA_WEB, ORCA_PTY and ORCA_WATCHER are required')
}

const req = createRequire(join(ROOT, 'package.json'))
const esbuild = req.resolve('esbuild/bin/esbuild')
const entry = await import(
  join(ROOT, 'config/scripts/orcad-distribution/server-bundle/orcad-entry-build.mjs')
)
const jsoncParserEsm = join(ROOT, 'node_modules', 'jsonc-parser', 'lib', 'esm', 'main.js')
const banner = 'var __orcadModuleUrl = require("node:url").pathToFileURL(__filename).href;'

async function bundle(entryPoint, outfile) {
  const args = [
    esbuild,
    entryPoint,
    '--bundle',
    '--platform=node',
    `--target=${entry.ORCAD_SERVER_BUILD_TARGET}`,
    '--format=cjs',
    `--outfile=${outfile}`,
    ...entry.ORCAD_EXTERNAL_MODULES.map((name) => `--external:${name}`),
    '--external:*.node',
    '--minify',
    '--legal-comments=eof',
    '--log-level=error',
    '--define:import.meta.url=__orcadModuleUrl',
    '--define:process.env.NODE_ENV="production"',
    `--banner:js=${banner}`,
    `--alias:jsonc-parser=${jsoncParserEsm}`,
  ]
  for (let attempt = 1; attempt <= 2; attempt += 1) {
    const result = spawnSync(process.execPath, args, { stdio: 'inherit' })
    if (result.status === 0 && existsSync(outfile)) {
      return
    }
    if (attempt === 2) {
      throw new Error(`esbuild failed for ${entryPoint} (exit ${result.status ?? result.signal})`)
    }
    console.warn(`esbuild crashed for ${entryPoint}; retrying with a fresh process`)
  }
}

rmSync(OUT, { recursive: true, force: true })
mkdirSync(OUT, { recursive: true })

for (const entryPoint of Object.values(entry.ORCAD_CHILD_ENTRY_POINTS)) {
  await bundle(join(ROOT, entryPoint), join(OUT, entry.orcadChildOutputFilename(entryPoint)))
}
await bundle(join(ROOT, entry.ORCAD_ENTRY_POINT), join(OUT, 'orcad-server.js'))
// Keep the trailing license comment ASCII, like the upstream packer does.
writeFileSync(join(OUT, 'orcad-server.js'), entry.escapeLegalCommentTail(readFileSync(join(OUT, 'orcad-server.js'), 'utf8')))

// The CLI ships bundled the way the upstream server artifact does; the tsc
// output in out/cli is unbundled and only meant to be packaged.
mkdirSync(join(OUT, 'out', 'cli'), { recursive: true })
await bundle(join(ROOT, 'src/cli/index.ts'), join(OUT, 'out', 'cli', 'index.js'))
const { version } = JSON.parse(readFileSync(join(ROOT, 'package.json'), 'utf8'))
writeFileSync(
  join(OUT, 'out', 'package.json'),
  `${JSON.stringify({ type: 'commonjs', private: true, version, commit: 'unknown' })}\n`
)

// Externals the server requires at runtime, with the OpenHarmony native addons.
mkdirSync(join(OUT, 'node_modules', '@parcel'), { recursive: true })
cpSync(join(ROOT, 'node_modules', 'node-pty'), join(OUT, 'node_modules', 'node-pty'), {
  recursive: true,
  dereference: true
})
cpSync(join(ROOT, 'node_modules', '@parcel', 'watcher'), join(OUT, 'node_modules', '@parcel', 'watcher'), {
  recursive: true,
  dereference: true
})
rmSync(join(OUT, 'node_modules', 'node-pty', 'prebuilds'), { recursive: true, force: true })
rmSync(join(OUT, 'node_modules', 'node-pty', 'build'), { recursive: true, force: true })
mkdirSync(join(OUT, 'node_modules', 'node-pty', 'build', 'orca-napi-openharmony-arm64'), { recursive: true })
cpSync(PTY, join(OUT, 'node_modules', 'node-pty', 'build', 'orca-napi-openharmony-arm64', 'pty.node'))
mkdirSync(join(OUT, 'node_modules', '@parcel', 'watcher', 'build', 'Release'), { recursive: true })
cpSync(WATCHER, join(OUT, 'node_modules', '@parcel', 'watcher', 'build', 'Release', 'watcher.node'))

// @parcel/watcher's JS wrapper resolves these helpers by name at require time;
// they are transitive dependencies, so copy each package next to it flatly.
function packageDir(name) {
  let current = dirname(req.resolve(name))
  for (;;) {
    const manifest = join(current, 'package.json')
    if (existsSync(manifest) && JSON.parse(readFileSync(manifest, 'utf8')).name === name) {
      return current
    }
    const parent = dirname(current)
    if (parent === current) {
      throw new Error(`cannot locate the ${name} package directory`)
    }
    current = parent
  }
}

for (const dependency of ['picomatch', 'is-glob', 'is-extglob', 'detect-libc']) {
  cpSync(packageDir(dependency), join(OUT, 'node_modules', dependency), {
    recursive: true,
    dereference: true
  })
}

if (!existsSync(join(WEB, 'web-index.html'))) {
  throw new Error(`the web client build is missing web-index.html: ${WEB}`)
}
cpSync(WEB, join(OUT, 'web'), { recursive: true })
cpSync(join(ROOT, 'resources', 'native-chat-visuals'), join(OUT, 'native-chat-visuals'), {
  recursive: true
})
console.log('orcad server bundle built')
