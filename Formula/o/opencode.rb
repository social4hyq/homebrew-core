class Opencode < Formula
  desc "AI coding agent terminal UI — HarmonyOS aarch64, built from source"
  homepage "https://github.com/anomalyco/opencode"
  url "https://github.com/anomalyco/opencode/archive/refs/tags/v1.18.18.tar.gz"
  sha256 "9962680e6ea7b59e002b2940a1f33f31f147fea4e976df2ea5501bc70ed2fb83"
  license "MIT"

  # PageMatch on github.com/releases/latest times out from slow networks (the
  # HTML page fetch), while api.github.com answers fast — same JSON strategy
  # as opencode@2.
  livecheck do
    url "https://api.github.com/repos/anomalyco/opencode/releases/latest"
    strategy :json do |json|
      json["tag_name"]&.gsub(/^v/, "")
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode-v1.18.18-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "28ea3f488bef73472a120b538c492ba967f8739c44032cd1f4071cbb2ba311d0"
  end

  # bun build --compile single binary: OHOS runtime + JS bundle + native .so embedded.
  # ohos-compat-shim statically linked since bun r31 — no runtime shim dependency.
  # Native deps via @ohos-ports/* package.json overrides (opentui-core, bun-pty,
  #   lightningcss, tailwindcss-oxide, @parcel/watcher).
  # bun install --ignore-scripts: tree-sitter-bash/-powershell would node-gyp build
  #   native bindings the app never loads (opencode uses web-tree-sitter wasm).
  # @parcel/watcher: inotify backend on OHOS via getBackend() openharmony patch.
  depends_on "bun" => :build
  depends_on "ohos-sdk" => :build # llvm-readelf (verify .codesign section)

  # All OHOS adaptations via inreplace — zero .patch files.
  # Version bumps only need url + sha256 + bottle root_url.

  def install
    ENV["BUN_TMPDIR"] = (buildpath/".bun-tmp").to_s
    (buildpath/".bun-tmp").mkpath
    # Persistent bun cache (buildpath is wiped each run).
    ENV["BUN_INSTALL_CACHE_DIR"] = (HOMEBREW_CACHE/"bun-install-cache").to_s

    # Workspace packages not needed for the CLI build (drops electron etc. from
    # the install set entirely).
    rm_r %w[packages/desktop packages/web packages/docs packages/storybook]

    # Redirect native deps to @ohos-ports musl builds.
    # nil check makes a vanished anchor fail loudly.
    inreplace "package.json" do |s|
      overrides = [
        '"@opentui/core": "npm:@ohos-ports/opentui-core@0.4.5-patch.1",',
        '    "bun-pty": "npm:@ohos-ports/bun-pty@0.4.10",',
        '    "lightningcss": "npm:@ohos-ports/lightningcss@1.32.0",',
        '    "@tailwindcss/oxide": "npm:@ohos-ports/tailwindcss-oxide@4.3.1",',
        '    "@parcel/watcher-linux-arm64-musl": "npm:@ohos-ports/parcel-watcher-openharmony-arm64@2.5.1",',
        '    "@parcel/watcher-openharmony-arm64": "npm:@ohos-ports/parcel-watcher-openharmony-arm64@2.5.1",',
      ]
      s.gsub!('"@opentui/core": "catalog:",', overrides.join("\n")) ||
        odie("opencode: @opentui/core override anchor not found in package.json")
    end

    # Use $HOME instead of read-only / for global projects.
    inreplace "packages/core/src/project.ts" do |s|
      s.sub!('import path from "path"', "import os from \"os\"\nimport path from \"path\"") ||
        odie("opencode: project.ts import anchor not found")
      s.sub!("path.parse(input).root", "os.homedir()") ||
        odie("opencode: project.ts path.parse anchor not found")
    end
    inreplace "packages/opencode/src/project/project.ts",
      "data.id === ProjectV2.ID.make(\"global\") && !data.vcs ? \"/\" : data.directory",
      "data.directory"

    # Skip open() on OHOS (no desktop browser).
    inreplace "packages/opencode/src/cli/cmd/web.ts",
      "open(localhostUrl).catch(() => {})",
      "if (process.platform !== \"openharmony\") open(localhostUrl).catch(() => {})"
    inreplace "packages/opencode/src/cli/cmd/web.ts",
      "open(displayUrl).catch(() => {})",
      "if (process.platform !== \"openharmony\") open(displayUrl).catch(() => {})"

    # File watcher: map openharmony → inotify backend in getBackend().
    inreplace "packages/core/src/filesystem/watcher.ts",
      'if (process.platform === "linux") return "inotify"',
      'if (process.platform === "linux" || process.platform === "openharmony") return "inotify"'

    # Flip openharmony-arm64 binding os:"none" → "openharmony" in bun.lock.
    # Version-independent: only touches os flag, not version/sha256 lines.
    # opoo on no-match (upstream may change format).
    lockfile = (buildpath/"bun.lock").read
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

    # build.ts: reuse linux-arm64-musl slot for OHOS — three inreplace calls:
    #   1. os check: allow linux-arm64-musl through on OHOS
    #   2. abi check: keep musl target on OHOS in single-flag mode
    #   3. compile target: use bun-linux-arm64-ohos for musl on OHOS
    inreplace "packages/opencode/script/build.ts" do |s|
      s.sub!("if (item.os !== process.platform || item.arch !== process.arch) {",
             "if ((item.os !== process.platform || item.arch !== process.arch) && " \
             "!(process.platform === \"openharmony\" && " \
             "item.os === \"linux\" && item.arch === \"arm64\" && " \
             "item.abi === \"musl\")) {") ||
        odie("opencode: build.ts os-filter anchor not found")
      s.sub!("if (item.abi !== undefined) {",
             "if (item.abi !== undefined && " \
             "!(process.platform === \"openharmony\" && " \
             "item.abi === \"musl\")) {") ||
        odie("opencode: build.ts abi-filter anchor not found")
      s.sub!("target: name.replace(pkg.name, \"bun\") as any,",
             "target: (process.platform === \"openharmony\" && " \
             "item.abi === \"musl\" ? \"bun-linux-arm64-ohos\" : " \
             "name.replace(pkg.name, \"bun\")) as any,") ||
        odie("opencode: build.ts compile-target anchor not found")
    end
    # Disable npm minimum-release-age policy (blocks fresh @ohos-ports packages).
    # inreplace raises on upstream reword; bun ignores unknown bunfig keys.
    inreplace "bunfig.toml", "minimumReleaseAge = 259200\n", ""
    system "bun", "install", "--ignore-scripts"

    # Script.version short-circuits on OPENCODE_VERSION (no git / registry lookup).
    ENV["OPENCODE_VERSION"] = version.to_s

    # build.ts compiles for bun-linux-arm64-ohos; bun embeds OHOS runtime
    # (no download) and bakes process.platform="openharmony" into the binary.
    # No --skip-install: build.ts's `bun install --os="*" --cpu="*"` resolves
    #   platform packages; openharmony filter skips linux-arm64-musl variants.
    cd "packages/opencode" do
      system "bun", "run", "script/build.ts", "--single"
    end

    out = "packages/opencode/dist/opencode-linux-arm64-musl/bin/opencode"
    odie "opencode binary missing" unless File.exist?(out)

    # Verify .codesign section present (bun's compile must sign the ELF).
    readelf = formula_opt_prefix("ohos-sdk")/"native/llvm/bin/llvm-readelf"
    sections = Utils.safe_popen_read(readelf.to_s, "--section-headers", out)
    odie "compiled binary lacks .codesign section" unless sections.include?(".codesign")

    # Shim statically linked since bun r31 — no LD_PRELOAD needed.
    # bun signs .so in-process during install.
    # Wrapper defaults TMPDIR to writable EL2 path (OHOS /tmp read-only).
    # opt_libexec for stable path across Cellar layout changes.
    mkdir_p libexec/"bin"
    libexec.install out => "bin/opencode"
    (bin/"opencode").write <<~SH
      #!/bin/sh
      export TMPDIR="${OPENCODE_TMPDIR:-/data/storage/el2/base/cache}"
      exec "#{opt_libexec}/bin/opencode" "$@"
    SH
    chmod 0755, bin/"opencode"

    # Handwritten zsh completion (upstream yargs only emits bash).
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

    # Bash completion from the binary itself (yargs generator, always in sync).
    generate_completions_from_executable(libexec/"bin/opencode", "completion", shells: [:bash])
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/opencode --version 2>&1")
  end
end
