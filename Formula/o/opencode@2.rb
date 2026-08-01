class OpencodeAT2 < Formula
  desc "OpenCode v2 preview — AI coding agent CLI, HarmonyOS aarch64, built from source"
  homepage "https://github.com/anomalyco/opencode"
  # v2 is a live development branch (no release tags yet). URL pins the v2
  # branch HEAD via git revision (bun.rb pattern); version stays a
  # human-readable beta tag so bump-formula-pr's version comparison doesn't
  # fight the commit SHA. livecheck watches the v2 branch HEAD via GitHub API;
  # autobump.yml opens a PR when a new commit lands.
  url "https://github.com/anomalyco/opencode.git", revision: "56c6add5c3d69e33da95aae48f567899ebe9906e", branch: "v2"
  version "2.0.0-beta"
  license "MIT"
  revision 3

  livecheck do
    url "https://api.github.com/repos/anomalyco/opencode/commits?sha=v2&per_page=1"
    strategy :json do |json|
      json.first&.dig("sha")
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/ohos-opencode@2-v2.0.0-beta-r3"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "69def17f44dcf944bae619f61ed56094f5303a361412efce94f0aed88492a9f1"
  end

  # opencode2 is a `bun build --compile` single binary: OHOS bun runtime + JS
  # bundle + native .so all embedded. Since bun r31 the ohos-compat-shim is
  # statically linked into every compile output, so there is NO runtime shim
  # dependency and no LD_PRELOAD wrapper.
  #
  # v2 monorepo restructure vs v1: the CLI package moved from packages/opencode
  # to packages/cli (binary renamed opencode -> opencode2). The build script is
  # at packages/cli/script/build.ts (rewritten, no web-UI embedding step). The
  # web.ts command was removed entirely (no patch needed). Native deps are
  # fewer: only @opentui/core (0.4.5) and bun-pty (0.4.10) need @ohos-ports/*
  # overrides; lightningcss/tailwindcss-oxide are gone from the CLI tree.
  #
  # `bun install --ignore-scripts` is intentional: lifecycle scripts are
  # irrelevant to signing, and trustedDependencies would fall back to source
  # builds on openharmony for native bindings the app never loads.
  #
  # @parcel/watcher: replaced linux-arm64-musl optional dep with @ohos-ports
  # pre-signed binary + getBackend() openharmony → inotify patch. File
  # watching is now functional on OHOS (inotify backend, no watchman).
  depends_on "bun" => :build
  depends_on "ohos-sdk" => :build # llvm-readelf (verify .codesign section)

  # All OHOS source adaptations are done via inreplace in install() — zero
  # .patch files. The "reuse musl slot" strategy (hijack the existing
  # linux-arm64-musl target entry instead of adding a new one) eliminates the
  # structural array-insertion hunk, leaving only single-line string
  # replacements. Version bumps only need url + sha256 + bottle root_url.
  # See social4hyq/ohos-opencode2 dev for the canonical diff these mirror
  # (fork-diff invariant).
  # 4 patches → inreplace 2026-07-31.

  def install
    ENV["BUN_TMPDIR"] = (buildpath/".bun-tmp").to_s
    (buildpath/".bun-tmp").mkpath
    ENV["BUN_INSTALL_CACHE_DIR"] = (HOMEBREW_CACHE/"bun-install-cache").to_s

    # Workspace packages not needed for the CLI build (drops electron, web
    # apps, storybook, etc. from the install set entirely). Only delete
    # packages matched by the "packages/*" glob — v2's root package.json also
    # lists explicit workspace entries ("packages/slack") and sub-globs
    # ("packages/console/*", "packages/stats/*") that bun install will hard-
    # error on if the directory is missing, so those stay.
    # session-ui is deleted alongside app: it references app's vendored SDK
    # tarball via file:../app/vendor/ (both have a file: dependency on a
    # .tgz inside packages/app/vendor/). The CLI dep chain doesn't touch
    # either.
    # enterprise is deleted alongside session-ui: it depends on
    # @opencode-ai/session-ui (workspace:*), so leaving it in place makes
    # bun install fail to resolve session-ui after its directory is gone.
    rm_r("packages/desktop")
    rm_r("packages/app")
    rm_r("packages/session-ui")
    rm_r("packages/web")
    rm_r("packages/www")
    rm_r("packages/storybook")
    rm_r("packages/enterprise")

    # Native dep overrides (replaces ohos-ports-deps.patch). v2 only needs
    # @ohos-ports/opentui-core + @ohos-ports/bun-pty (no lightningcss/
    # tailwindcss-oxide in the CLI tree).
    inreplace "bunfig.toml",
      '"@opentui/core-win32-x64", ',
      '"@opentui/core-win32-x64", ' \
      '"@ohos-ports/opentui-core", "@ohos-ports/bun-pty", '
    inreplace "package.json" do |s|
      s.gsub! '"@opentui/core": "catalog:",',
              '"@opentui/core": "npm:@ohos-ports/opentui-core@0.4.5-patch.1",'
      s.gsub! %Q(    "effect": "catalog:"\n  },),
              "    \"effect\": \"catalog:\",\n    " \
              "\"bun-pty\": \"npm:@ohos-ports/bun-pty@0.4.10\",\n    " \
              "\"@parcel/watcher-linux-arm64-musl\": \"npm:@ohos-ports/parcel-watcher-openharmony-arm64@2.5.1\"\n  " \
              "},"
    end

    # Home dir fallback for global projects (replaces project-global-
    # worktree.patch). v2 only touches packages/core/src/project.ts
    # (no packages/opencode variant).
    inreplace "packages/core/src/project.ts" do |s|
      s.sub! 'import path from "path"', "import os from \"os\"\nimport path from \"path\""
      s.sub! "path.parse(input).root", "os.homedir()"
    end

    # File watcher: add openharmony → inotify backend mapping so getBackend()
    # returns "inotify" instead of undefined on OHOS (enables native file watching).
    inreplace "packages/core/src/filesystem/watcher.ts",
      'if (process.platform === "linux") return "inotify"',
      'if (process.platform === "linux" || process.platform === "openharmony") return "inotify"'

    # Flip openharmony-arm64 os markers in bun.lock (replaces
    # bun-lock-openharmony-os.patch). Same regex as opencode.
    lockfile = (buildpath/"bun.lock").read
    injected = lockfile.gsub(
      /("[^"]*openharmony-arm64@[^"]+", "", \{ )"os": "none"(, "cpu": "arm64" \})/,
      %q(\1"os": "openharmony"\2),
    )
    if injected == lockfile
      opoo "opencode@2: no openharmony-arm64 os:none markers found in bun.lock " \
           "(upstream may have changed the lockfile format — verify the build)"
    else
      (buildpath/"bun.lock").atomic_write(injected)
    end

    # Allow freshly-published @ohos-ports/* packages (npm anti-typosquatting
    # minimum-release-age policy blocks packages < 3 days old by default).
    (buildpath/"bunfig.toml").atomic_write("[install]\nminimumReleaseAgeMs = 0\n")
    system "bun", "install", "--ignore-scripts"

    # Script.version short-circuits on OPENCODE_VERSION (no git / registry
    # lookup), which also flips Script.channel to "latest".
    ENV["OPENCODE_VERSION"] = version.to_s

    # build.ts adaptations (replaces build-ohos-target.patch). Reuse the
    # existing linux-arm64-musl target slot instead of adding a new one:
    #   1. os check: allow linux-arm64-musl through on OHOS
    #   2. abi check: keep musl target on OHOS in single-flag mode
    #   3. compile target: use bun-linux-arm64-ohos for musl on OHOS
    inreplace "packages/cli/script/build.ts",
      "if (item.os !== process.platform || item.arch !== process.arch) return false",
      "if ((item.os !== process.platform || item.arch !== process.arch) && " \
      "!(process.platform === \"openharmony\" && " \
      "item.os === \"linux\" && item.arch === \"arm64\" && " \
      "item.abi === \"musl\")) return false"
    inreplace "packages/cli/script/build.ts",
      "return item.abi === undefined",
      "return process.platform === \"openharmony\" || item.abi === undefined"
    inreplace "packages/cli/script/build.ts" do |s|
      s.sub! "target: target.replace(binary, \"bun\") as Bun.Build.CompileTarget,",
             "target: (process.platform === \"openharmony\" && " \
             "item.abi === \"musl\" ? \"bun-linux-arm64-ohos\" : " \
             "target.replace(binary, \"bun\")) as Bun.Build.CompileTarget,"
    end

    cd "packages/cli" do
      system "bun", "run", "script/build.ts", "--single"
    end

    out = "packages/cli/dist/cli-linux-arm64-musl/bin/opencode2"
    odie "opencode2 binary missing" unless File.exist?(out)

    # The device kernel refuses to exec unsigned ELFs; bun's compile step must
    # have produced a .codesign section (ohos_sign, bun.rb r16+).
    readelf = formula_opt_prefix("ohos-sdk")/"native/llvm/bin/llvm-readelf"
    sections = Utils.safe_popen_read(readelf.to_s, "--section-headers", out)
    odie "compiled binary lacks .codesign section" unless sections.include?(".codesign")

    # The launcher wrapper defaults TMPDIR to a writable EL2 path (OHOS /tmp
    # is read-only in app contexts); override via OPENCODE_TMPDIR. Self-reference
    # via opt_libexec (not libexec) so the baked path stays stable across the
    # HOMEBREW_CELLAR flat/nested flip.
    #
    # The wrapper also isolates XDG_DATA_HOME: v2 and opencode (v1)
    # would otherwise share ~/.local/share/opencode/opencode.db, and v2's
    # migrations (e.g. event.created NOT NULL) break v1's session creation
    # ("creating a session failed"). v2 gets its own data root; an
    # explicitly-set XDG_DATA_HOME is still honored.
    mkdir_p libexec/"bin"
    libexec.install out => "bin/opencode2"
    (bin/"opencode2").write <<~SH
      #!/bin/sh
      export TMPDIR="${OPENCODE_TMPDIR:-/data/storage/el2/base/cache}"
      export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share-v2}"
      exec "#{opt_libexec}/bin/opencode2" "$@"
    SH
    chmod 0755, bin/"opencode2"

    # Static zsh completion: upstream has no completion generator. Top-level
    # commands from packages/cli/src/commands/commands.ts (v2 @ 3b0d8f0).
    (zsh_completion/"_opencode2").write <<~'ZSH'
      #compdef opencode2

      _opencode2() {
        local -a commands
        commands=(
          'acp:Start an Agent Client Protocol server'
          'api:Make a request to the running server'
          'auth:Manage authentication'
          'console:Manage OpenCode Console access'
          'debug:Debugging and troubleshooting tools'
          'mcp:Manage MCP servers'
          'migrate:Migrate v1 data to v2'
          'mini:Start the minimal interactive interface'
          'plugin:Manage plugins'
          'run:Run OpenCode with a message'
          'service:Manage the background server'
          'pair:Show server pairing information'
          'serve:Start the v2 API server'
        )
        _arguments -C \
          '(-h --help)'{-h,--help}'[show help]' \
          '(-v --version)'{-v,--version}'[show version]' \
          '1:command:->command' \
          '*::arg:->args'
        case $state in
          command)
            _describe -t commands 'opencode2 command' commands
            ;;
          args)
            case $words[1] in
              mcp)
                local -a mcp_cmds
                mcp_cmds=('list:List MCP servers' 'add:Add an MCP server' 'auth:Authenticate an MCP server' 'logout:Remove MCP auth')
                _describe -t commands 'mcp command' mcp_cmds
                ;;
              service)
                local -a svc_cmds
                svc_cmds=('start:Start the server' 'restart:Restart the server' 'status:Show server status' 'stop:Stop the server' 'get:Get config' 'set:Set config' 'unset:Unset config')
                _describe -t commands 'service command' svc_cmds
                ;;
              debug)
                local -a debug_cmds
                debug_cmds=('agents:List all agents')
                _describe -t commands 'debug command' debug_cmds
                ;;
              auth)
                local -a auth_cmds
                auth_cmds=('connect:Connect to an auth provider')
                _describe -t commands 'auth command' auth_cmds
                ;;
              console)
                local -a console_cmds
                console_cmds=('login:Log in to Console')
                _describe -t commands 'console command' console_cmds
                ;;
              plugin)
                local -a plugin_cmds
                plugin_cmds=('list:List active plugins')
                _describe -t commands 'plugin command' plugin_cmds
                ;;
            esac
            ;;
        esac
      }

      _opencode2 "$@"
    ZSH
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/opencode2 --version 2>&1")
  end
end
