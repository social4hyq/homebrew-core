class Opencode < Formula
  desc "AI coding agent terminal UI — HarmonyOS aarch64, built from source"
  homepage "https://github.com/anomalyco/opencode"
  url "https://github.com/anomalyco/opencode/archive/refs/tags/v1.18.10.tar.gz"
  sha256 "3df0c573473d3492990bdeb69e6653eaab485394f95ad1c1a897329f4209f430"
  license "MIT"
  revision 1

  # PageMatch on github.com/releases/latest times out from slow networks (the
  # HTML page fetch), while api.github.com answers fast — same JSON strategy
  # as ohos-opencode@2.
  livecheck do
    url "https://api.github.com/repos/anomalyco/opencode/releases/latest"
    strategy :json do |json|
      json["tag_name"]&.gsub(/^v/, "")
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode-v1.18.10-r4"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e823f5b8e3f996c160da2a7cbcd9d011404cc9e90b7e0c9b7bebb0e35d26e9eb"
  end

  # opencode is a `bun build --compile` single binary: OHOS bun runtime + JS
  # bundle + native .so all embedded. Since bun r31 the ohos-compat-shim is
  # statically linked into every compile output, so there is NO runtime shim
  # dependency and no LD_PRELOAD wrapper (see below).
  #
  # Native deps come from @ohos-ports/* npm packages via package.json override
  # aliases (see Patches/ohos-opencode/ohos-ports-deps.patch): opentui-core
  # (bundled musl libopentui.so via file-loader import, 0.4.5-patch.1+), bun-pty,
  # lightningcss, tailwindcss-oxide. bun signs extracted .node/.so in-process
  # during `bun install`, and `bun build --compile` re-signs its output ELF
  # (bun.rb r16+), so no external signing pass is needed here — install()
  # asserts the .codesign section is present instead.
  #
  # `bun install --ignore-scripts` is intentional: lifecycle scripts are
  # irrelevant to signing, and tree-sitter-bash/-powershell (in
  # trustedDependencies) would fall back to a node-gyp source build on
  # openharmony (no prebuilds) for native bindings the app never loads —
  # opencode uses web-tree-sitter (wasm) at runtime.
  #
  # @parcel/watcher: replaced linux-arm64-musl optional dep with @ohos-ports
  # pre-signed binary + getBackend() openharmony → inotify patch. File
  # watching is now functional on OHOS (inotify backend, no watchman).
  depends_on "bun" => :build
  depends_on "ohos-sdk" => :build # llvm-readelf (verify .codesign section)

  # All OHOS source adaptations are done via inreplace in install() — zero
  # .patch files. The "reuse musl slot" strategy hijacks the existing
  # linux-arm64-musl target entry instead of adding a new one. Two filter
  # checks must be modified: the os/platform guard AND the abi guard.
  # (web-open-try-catch.patch → inreplace 2026-07-31;
  #  build-ohos-target.patch → inreplace 2026-07-31.)
  # Version bumps only need url + sha256 + bottle root_url.
  # See social4hyq/ohos-opencode dev for the canonical diff these mirror
  # (fork-diff invariant).

  def install
    ENV["BUN_TMPDIR"] = (buildpath/".bun-tmp").to_s
    (buildpath/".bun-tmp").mkpath
    # Persistent bun cache: buildpath is wiped each run, which would re-download
    # every package after a network hiccup. (The env var is BUN_INSTALL_CACHE_DIR;
    # BUN_INSTALL_CACHE is a no-op.)
    ENV["BUN_INSTALL_CACHE_DIR"] = (HOMEBREW_CACHE/"bun-install-cache").to_s

    # Workspace packages not needed for the CLI build (drops electron etc. from
    # the install set entirely).
    rm_r("packages/desktop")
    rm_r("packages/web")
    rm_r("packages/docs")
    rm_r("packages/storybook")

    # Redirect native deps to the @ohos-ports/* musl builds (replaces
    # ohos-ports-deps.patch). Pure string/array edits, version-independent.
    # Append the @ohos-ports/* entries to bunfig.toml's excludes array.
    inreplace "bunfig.toml",
      '"@opentui/core-win32-x64", ',
      '"@opentui/core-win32-x64", ' \
      '"@ohos-ports/opentui-core", "@ohos-ports/bun-pty", ' \
      '"@ohos-ports/lightningcss", "@ohos-ports/tailwindcss-oxide", '
    inreplace "package.json" do |s|
      s.gsub! '"@opentui/core": "catalog:",',
              '"@opentui/core": "npm:@ohos-ports/opentui-core@0.4.5-patch.1",'
      # bun-pty/lightningcss/@tailwindcss/oxide have no upstream override
      # entry, so add them after @types/node (last key in overrides).
      node_old = %Q(    "@types/node": "catalog:"\n  },)
      node_new = [
        '    "@types/node": "catalog:",',
        '    "bun-pty": "npm:@ohos-ports/bun-pty@0.4.10",',
        '    "lightningcss": "npm:@ohos-ports/lightningcss@1.32.0",',
        '    "@tailwindcss/oxide": "npm:@ohos-ports/tailwindcss-oxide@4.3.1",',
        '    "@parcel/watcher-linux-arm64-musl": "npm:@ohos-ports/parcel-watcher-openharmony-arm64@2.5.1",',
        '    "@parcel/watcher-openharmony-arm64": "npm:@ohos-ports/parcel-watcher-openharmony-arm64@2.5.1"',
        "  },",
      ].join("\n")
      s.gsub!(node_old, node_new)
    end

    # Project global dir: use $HOME instead of filesystem root when no git repo
    # is found (replaces project-global-worktree.patch). on openharmony the root
    # path is read-only, so a "global" project lands in the home dir.
    inreplace "packages/core/src/project.ts" do |s|
      s.sub! 'import path from "path"', "import os from \"os\"\nimport path from \"path\""
      s.sub! "path.parse(input).root", "os.homedir()"
    end
    inreplace "packages/opencode/src/project/project.ts",
      "data.id === ProjectV2.ID.make(\"global\") && !data.vcs ? \"/\" : data.directory",
      "data.directory"

    # web.ts: skip open() on OHOS (no desktop browser). Upstream already has
    # .catch(() => {}) for error tolerance, so this is a single-line platform
    # guard — no DISPLAY/WAYLAND checks needed (unlike the old .patch).
    # Replaces web-open-try-catch.patch.
    inreplace "packages/opencode/src/cli/cmd/web.ts",
      "open(localhostUrl).catch(() => {})",
      "if (process.platform !== \"openharmony\") open(localhostUrl).catch(() => {})"
    inreplace "packages/opencode/src/cli/cmd/web.ts",
      "open(displayUrl).catch(() => {})",
      "if (process.platform !== \"openharmony\") open(displayUrl).catch(() => {})"

    # File watcher: add openharmony → inotify backend mapping so getBackend()
    # returns "inotify" instead of undefined on OHOS (enables native file watching).
    # Runtime require path is handled by the package.json override above
    # (@parcel/watcher-openharmony-arm64 → @ohos-ports).
    inreplace "packages/core/src/filesystem/watcher.ts",
      'if (process.platform === "linux") return "inotify"',
      'if (process.platform === "linux" || process.platform === "openharmony") return "inotify"'

    # Inject openharmony os markers into bun.lock — replaces the old
    # bun-lock-openharmony-os.patch (codex.rb pattern: inreplace instead of a
    # .patch for a generated file). Version-independent; see note above.
    lockfile = (buildpath/"bun.lock").read
    # Upstream marks every *-openharmony-arm64 native binding definition as
    # { "os": "none" } (unknown platform); bun won't resolve them on openharmony.
    # Flip just that fragment to "openharmony" so build.ts's
    # `bun install --os="*" --cpu="*"` picks them up. Version-independent: it
    # never touches version or sha256 lines, only the os flag on binding defs.
    injected = lockfile.gsub(
      /("[^"]*openharmony-arm64@[^"]+", "", \{ )"os": "none"(, "cpu": "arm64" \})/,
      %q(\1"os": "openharmony"\2),
    )
    if injected == lockfile
      opoo "opencode: no openharmony-arm64 os:none markers found in bun.lock " \
           "(upstream may have changed the lockfile format — verify the build)"
    else
      (buildpath/"bun.lock").atomic_write(injected)
    end

    # build.ts adaptations (replaces build-ohos-target.patch). Reuse the
    # existing linux-arm64-musl target slot — three inreplace calls:
    #   1. os check: allow linux-arm64-musl through on OHOS
    #   2. abi check: keep musl target on OHOS in single-flag mode
    #   3. compile target: use bun-linux-arm64-ohos for musl on OHOS
    inreplace "packages/opencode/script/build.ts" do |s|
      # V1 filter checks item.os !== process.platform first — linux-os target
      # would be rejected on OHOS before reaching the abi guard. Allow
      # linux-arm64-musl to pass on OHOS.
      s.sub! "if (item.os !== process.platform || item.arch !== process.arch) {",
             "if ((item.os !== process.platform || item.arch !== process.arch) && " \
             "!(process.platform === \"openharmony\" && " \
             "item.os === \"linux\" && item.arch === \"arm64\" && " \
             "item.abi === \"musl\")) {"
      s.sub! "if (item.abi !== undefined) {",
             "if (item.abi !== undefined && " \
             "!(process.platform === \"openharmony\" && " \
             "item.abi === \"musl\")) {"
      s.sub! "target: name.replace(pkg.name, \"bun\") as any,",
             "target: (process.platform === \"openharmony\" && " \
             "item.abi === \"musl\" ? \"bun-linux-arm64-ohos\" : " \
             "name.replace(pkg.name, \"bun\")) as any,"
    end
    # Allow freshly-published @ohos-ports/* packages (npm anti-typosquatting
    # minimum-release-age policy blocks packages < 3 days old by default).
    (buildpath/"bunfig.toml").atomic_write("[install]\nminimumReleaseAgeMs = 0\n")
    system "bun", "install", "--ignore-scripts"

    # Script.version short-circuits on OPENCODE_VERSION (no git / registry
    # lookup), which also flips Script.channel to "latest".
    ENV["OPENCODE_VERSION"] = version.to_s

    # build.ts (patched) compiles for bun-linux-arm64-ohos, which equals
    # CompileTarget::default() on OHOS — bun embeds the running OHOS runtime
    # directly (no local runtime file, no download) and bakes
    # process.platform="openharmony" into the binary.
    #
    # No --skip-install: build.ts's internal `bun install --os="*" --cpu="*"`
    # passes are required here. bun's bundler hard-errors on imports of
    # platform packages matching the compile target (linux-arm64-musl), and
    # the openharmony install filter skips exactly those (fff-bun, opentui,
    # parcel-watcher variants are all os-gated to linux/darwin/win32).
    cd "packages/opencode" do
      system "bun", "run", "script/build.ts", "--single"
    end

    out = "packages/opencode/dist/opencode-linux-arm64-musl/bin/opencode"
    odie "opencode binary missing" unless File.exist?(out)

    # The device kernel refuses to exec unsigned ELFs; bun's compile step must
    # have produced a .codesign section (ohos_sign, bun.rb r16+).
    readelf = formula_opt_prefix("ohos-sdk")/"native/llvm/bin/llvm-readelf"
    sections = Utils.safe_popen_read(readelf.to_s, "--section-headers", out)
    odie "compiled binary lacks .codesign section" unless sections.include?(".codesign")

    # The OHOS bun runtime calls close_range(2) at startup, which app seccomp
    # policies (hishell, this build context, ...) block with SIGSYS. Bun r31+
    # statically links ohos-compat-shim into every `bun build --compile`
    # output, so the interposer is already in the binary — no LD_PRELOAD of
    # libohos_compat.so is needed (that was the r1/r2 wrapper, now removed).
    #
    # dlopen-sign-shim is NOT needed here, unlike opencode-shim.rb: bun signs the
    # @ohos-ports native .so in-process during `bun install`, and the embed
    # (`with { type: "file" }`) preserves those bytes, so the runtime-extracted
    # libraries are already signed.
    #
    # The launcher wrapper remains only to default TMPDIR to a writable EL2
    # path (OHOS /tmp is read-only in app contexts); override via
    # OPENCODE_TMPDIR. Self-reference via opt_libexec (not libexec) so the
    # baked path stays stable across the HOMEBREW_CELLAR flat/nested flip
    # (wrapper conventions: README "CLI wrapper 约定").
    mkdir_p libexec/"bin"
    libexec.install out => "bin/opencode"
    (bin/"opencode").write <<~SH
      #!/bin/sh
      export TMPDIR="${OPENCODE_TMPDIR:-/data/storage/el2/base/cache}"
      exec "#{opt_libexec}/bin/opencode" "$@"
    SH
    chmod 0755, bin/"opencode"

    # Static zsh completion: upstream's own generator (`opencode completion`,
    # yargs) only emits a bash-style script — the zsh/fish args are silently
    # ignored — so zsh stays handwritten here. Command list synced with
    # packages/opencode/src/index.ts @ v1.18.10 (note: `auth` is an alias of
    # `providers` since v1.18.9; `account`/`tui` were added after v1.18.8).
    (zsh_completion/"_opencode").write <<~'ZSH'
      #compdef opencode

      _opencode() {
        local -a commands
        commands=(
          'account:Manage OpenCode Console account'
          'acp:Start ACP (Agent Client Protocol) server'
          'agent:Manage agents'
          'attach:Attach to a running opencode server'
          'auth:Alias for providers'
          'db:Database utilities'
          'debug:Debug utilities'
          'export:Export a session'
          'generate:Generate artifacts'
          'github:GitHub integration'
          'import:Import a session from file'
          'mcp:Manage MCP servers'
          'models:List models'
          'plug:Manage plugins'
          'pr:Check out a pull request'
          'providers:Manage providers'
          'run:Run opencode with a message'
          'serve:Start the opencode server'
          'session:Manage sessions'
          'stats:Show usage statistics'
          'tui:Start the TUI (default command)'
          'uninstall:Uninstall opencode'
          'upgrade:Upgrade opencode'
          'web:Start the web interface'
        )
        _arguments -C \
          '(-h --help)'{-h,--help}'[show help]' \
          '(-v --version)'{-v,--version}'[show version]' \
          '1:command:->command' \
          '*::arg:->args'
        case $state in
          command)
            _describe -t commands 'opencode command' commands
            ;;
          args)
            case $words[1] in
              mcp)
                local -a mcp_cmds
                mcp_cmds=('list:List MCP servers' 'auth:Authenticate an MCP server' 'logout:Remove MCP auth')
                _describe -t commands 'mcp command' mcp_cmds
                ;;
              session)
                local -a session_cmds
                session_cmds=('list:List sessions' 'delete:Delete a session')
                _describe -t commands 'session command' session_cmds
                ;;
              auth)
                local -a auth_cmds
                auth_cmds=('login:Log in to a provider' 'logout:Log out of a provider' 'list:List credentials')
                _describe -t commands 'auth command' auth_cmds
                ;;
              db)
                local -a db_cmds
                db_cmds=('path:Print database path')
                _describe -t commands 'db command' db_cmds
                ;;
            esac
            ;;
        esac
      }

      _opencode "$@"
    ZSH

    # Bash completion comes from the binary itself (yargs generator) — always
    # in sync, unlike the handwritten zsh one above. Generate from the libexec
    # binary: the bin/opencode wrapper execs opt_libexec, whose opt/ symlink
    # only exists after install (same pattern as grok-build/cc-switch).
    generate_completions_from_executable(libexec/"bin/opencode", "completion", shells: [:bash])
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/opencode --version 2>&1")
  end
end
