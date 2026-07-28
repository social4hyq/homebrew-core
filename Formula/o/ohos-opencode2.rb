class OhosOpencode2 < Formula
  desc "OpenCode v2 preview — AI coding agent CLI, HarmonyOS aarch64, built from source"
  homepage "https://github.com/anomalyco/opencode"
  url "https://github.com/anomalyco/opencode/archive/3b0d8f0e6f3d6f645b321b36686aa0288b3b5796.tar.gz"
  version "2.0.0-dev"
  sha256 "f2b23e5e1d7ea15eeb398312e0d0d1e24cc42226f99d1175ded7ce695cee53fc"
  license "MIT"

  # v2 is a live development branch (no release tags yet). The URL pins to a
  # specific upstream commit on the `v2` branch; updates require changing both
  # the url + sha256 AND regenerating patches from the fork's dev branch
  # (social4hyq/ohos-opencode2, always manual — same invariant as ohos-opencode).
  livecheck do
    skip "v2 has no release tags; update manually"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/ohos-opencode2-v2.0.0-dev-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0000000000000000000000000000000000000000000000000000000000000000"
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
  # @parcel/watcher needs no handling: opencode lazy-loads it with try/catch
  # and degrades gracefully on openharmony (file watching disabled, no crash).
  depends_on "bun" => :build
  depends_on "ohos-sdk" => :build # llvm-readelf (verify .codesign section)

  # OHOS adaptations, mirrored from social4hyq/ohos-opencode2 dev (patches are
  # the `git diff <pinned-commit>..dev` for the respective files — regenerate
  # there, never hand-edit hunks).
  patch :p1 do
    file "Patches/ohos-opencode2/ohos-ports-deps.patch"
  end
  patch :p1 do
    file "Patches/ohos-opencode2/bun-lock-openharmony-os.patch"
  end
  patch :p1 do
    file "Patches/ohos-opencode2/build-ohos-target.patch"
  end
  patch :p1 do
    file "Patches/ohos-opencode2/project-global-worktree.patch"
  end

  def install
    ENV["BUN_TMPDIR"] = (buildpath/".bun-tmp").to_s
    (buildpath/".bun-tmp").mkpath
    ENV["BUN_INSTALL_CACHE_DIR"] = (HOMEBREW_CACHE/"bun-install-cache").to_s

    # Workspace packages not needed for the CLI build (drops electron, web
    # apps, storybook, etc. from the install set entirely).
    rm_r("packages/desktop")
    rm_r("packages/app")
    rm_r("packages/web")
    rm_r("packages/www")
    rm_r("packages/storybook")
    rm_r("packages/console")
    rm_r("packages/stats")
    rm_r("packages/slack")

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
    # pass is required here. bun's bundler hard-errors on imports of platform
    # packages matching the compile target (linux-arm64-musl), and the
    # openharmony install filter skips exactly those (fff-bun, opentui,
    # parcel-watcher variants are all os-gated to linux/darwin/win32).
    cd "packages/cli" do
      system "bun", "run", "script/build.ts", "--single"
    end

    out = "packages/cli/dist/cli-openharmony-arm64-musl/bin/opencode2"
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
    mkdir_p libexec/"bin"
    libexec.install out => "bin/ohos-opencode2"
    (bin/"ohos-opencode2").write <<~SH
      #!/bin/sh
      export TMPDIR="${OPENCODE_TMPDIR:-/data/storage/el2/base/cache}"
      exec "#{opt_libexec}/bin/ohos-opencode2" "$@"
    SH
    chmod 0755, bin/"ohos-opencode2"

    # Static zsh completion: upstream has no completion generator. Top-level
    # commands from packages/cli/src/commands/commands.ts (v2 @ 3b0d8f0).
    (zsh_completion/"_ohos-opencode2").write <<~'ZSH'
      #compdef ohos-opencode2

      _ohos-opencode2() {
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
            _describe -t commands 'ohos-opencode2 command' commands
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

      _ohos-opencode2 "$@"
    ZSH
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ohos-opencode2 --version 2>&1")
  end
end
