class OhosOpencode < Formula
  desc "AI coding agent terminal UI — HarmonyOS aarch64, built from source"
  homepage "https://github.com/anomalyco/opencode"
  url "https://github.com/anomalyco/opencode/archive/refs/tags/v1.18.3.tar.gz"
  sha256 "494041aedd7407079f91fd694de355f4ff022ba6bf876e09ff30983bbdc70ae1"
  license "MIT"
  revision 1

  livecheck do
    url "https://github.com/anomalyco/opencode/releases/latest"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/ohos-opencode-v1.18.3-r2"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e29526f148b3cdc1021bf1b357b9f6adb2508950afe607952220a960059f0bfb"
  end

  # opencode is a `bun build --compile` single binary: OHOS bun runtime + JS
  # bundle + native .so all embedded. Runtime dependency: ohos-compat-shim
  # only (see wrapper below).
  #
  # Native deps come from @ohos-ports/* npm packages via package.json override
  # aliases (see Patches/ohos-opencode/ohos-ports-deps.patch): opentui-core
  # (bundled musl libopentui.so via file-loader import, 0.4.4+), bun-pty,
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
  # @parcel/watcher needs no handling: opencode lazy-loads it with try/catch
  # and degrades gracefully on openharmony (file watching disabled, no crash).
  depends_on "bun" => :build
  depends_on "ohos-sdk" => :build # llvm-readelf (verify .codesign section)
  depends_on "social4hyq/core/ohos-compat-shim"

  # OHOS adaptations, mirrored from social4hyq/ohos-opencode dev (patches are
  # the `git diff v1.18.3..dev` for the respective files — regenerate there,
  # never hand-edit hunks).
  patch :p1 do
    file "Patches/ohos-opencode/ohos-ports-deps.patch"
  end
  patch :p1 do
    file "Patches/ohos-opencode/bun-lock-openharmony-os.patch"
  end
  patch :p1 do
    file "Patches/ohos-opencode/build-ohos-target.patch"
  end
  patch :p1 do
    file "Patches/ohos-opencode/project-global-worktree.patch"
  end
  patch :p1 do
    file "Patches/ohos-opencode/web-open-try-catch.patch"
  end

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

    out = "packages/opencode/dist/opencode-openharmony-arm64-musl/bin/opencode"
    odie "opencode binary missing" unless File.exist?(out)

    # The device kernel refuses to exec unsigned ELFs; bun's compile step must
    # have produced a .codesign section (ohos_sign, bun.rb r16+).
    readelf = formula_opt_prefix("ohos-sdk")/"native/llvm/bin/llvm-readelf"
    sections = Utils.safe_popen_read(readelf.to_s, "--section-headers", out)
    odie "compiled binary lacks .codesign section" unless sections.include?(".codesign")

    # The raw binary must not go straight into bin: the OHOS bun runtime calls
    # close_range(2) at startup, which app seccomp policies (hishell, this
    # build context, ...) block with SIGSYS — the process dies with "invalid
    # system call (core dumped)" before printing anything. ohos-compat-shim
    # intercepts close_range (and friends) in libc, so the launcher preloads
    # it. Self-reference via opt_libexec (not libexec) so the baked path stays
    # stable across the HOMEBREW_CELLAR flat/nested flip (see opencode.rb).
    #
    # dlopen-sign-shim is NOT needed here, unlike opencode.rb: bun signs the
    # @ohos-ports native .so in-process during `bun install`, and the embed
    # (`with { type: "file" }`) preserves those bytes, so the runtime-extracted
    # libraries are already signed. Verified: TUI renders with only
    # libohos_compat.so preloaded.
    mkdir_p libexec/"bin"
    libexec.install out => "bin/ohos-opencode"
    (bin/"ohos-opencode").write <<~SH
      #!/bin/sh
      export LD_PRELOAD="#{formula_opt_lib("ohos-compat-shim")}/libohos_compat.so${LD_PRELOAD:+:$LD_PRELOAD}"
      export TMPDIR="${OPENCODE_TMPDIR:-/data/storage/el2/base/cache}"
      exec "#{opt_libexec}/bin/ohos-opencode" "$@"
    SH
    chmod 0755, bin/"ohos-opencode"

    # Static zsh completion: upstream has no completion generator. Top-level
    # commands from packages/opencode/src/cli/cmd/*.ts (v1.18.3).
    (zsh_completion/"_ohos-opencode").write <<~'ZSH'
      #compdef ohos-opencode

      _ohos-opencode() {
        local -a commands
        commands=(
          'acp:Start ACP (Agent Client Protocol) server'
          'agent:Manage agents'
          'attach:Attach to a running opencode server'
          'auth:Manage provider credentials'
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
            _describe -t commands 'ohos-opencode command' commands
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

      _ohos-opencode "$@"
    ZSH
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ohos-opencode --version 2>&1")
  end
end
