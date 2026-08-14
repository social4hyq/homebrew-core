class DeepseekHarness < Formula
  desc "Profile-bootable AI agent (web, headless and tui profiles)"
  homepage "https://github.com/deepseek-ai/deepseek-harness"
  url "https://registry.npmmirror.com/@deepseek-ai/dsh/-/dsh-0.1.0-rc.6.tgz"
  sha256 "1b8a9a0ad3c7feaece47926e0bd37ca151c7ccfa997953afa5fd01261784eadc"
  license "MIT"

  livecheck do
    # www.npmjs.com 403s from this env; registry API JSON is reachable (same
    # pattern as claude-code.rb).
    url "https://registry.npmjs.org/@deepseek-ai/dsh/latest"
    regex(/"version":\s*"([^"]+)"/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/deepseek-harness-v0.1.0-rc.6-r2"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6657cb839c2413020904536b6ea9e08d2cc3e6cb816185c5069924764cc7ddf7"
  end

  # bun: install-time dependency tree (blocks native postinstalls — koffi's
  #      source build fails on OHOS; the windows-acl stub below makes it dead
  #      code anyway). node: runtime. ohos-compat-shim: its link() hook covers
  #      dsh's session-persistence hard-link (.tmp -> .zstd atomic replace),
  #      which OHOS blocks globally (EPERM); also fixes os.userInfo() ENOENT.
  depends_on "bun" => :build
  depends_on "node"
  depends_on "ohos-compat-shim"

  def install
    cd buildpath do
      system formula_opt_bin("bun")/"bun", "install"
      system formula_opt_bin("bun")/"bun", "add", "@img/sharp-wasm32"
      # dsh-sandbox-local unconditionally static-imports dsh-sandbox-windows-acl
      # (Win32-only ACL code), which static-imports koffi — whose top-level
      # native init crashes without an OHOS prebuilt. All koffi use is Win32-only
      # (loads kernel32.dll/advapi32.dll), so on Linux/OHOS these symbols are
      # never invoked. Replace the real module with a 4-symbol stub in the
      # build tree before installing (File.write overwrites; Homebrew's
      # Pathname#write refuses to overwrite an existing file).
      File.write("node_modules/@deepseek-ai/dsh-sandbox-windows-acl/lib/index.js", <<~JS)
        // OHOS bypass stub: see deepseek-harness formula. Win32-only dead code.
        export const AclWriteGrant = undefined;
        export const assertTempRootOutsideWorkspace = () => {};
        export const tempWriteSid = () => undefined;
        export const workspaceWriteSid = () => undefined;
        export {};
      JS
      libexec.install Dir["*"]
    end

    # bin/dsh wrapper: ohos-shim (LD_PRELOAD libohos_compat.so) + node
    # --expose-internals (HMR plugin requires it; cannot go in NODE_OPTIONS).
    # Runtime $HOMEBREW_PREFIX only — no build-time path interpolation
    # (relocatability, same rationale as claude-code.rb).
    (bin/"dsh").write <<~SH
      #!/bin/sh
      set -eu
      HB="${HOMEBREW_PREFIX:-$HOME/.harmonybrew}"
      NODE="$HB/opt/node/bin/node"
      SHIM="$HB/opt/ohos-compat-shim/bin/ohos-shim"
      DSH_BIN="$HB/opt/#{name}/libexec/lib/bin.js"
      PORT=3080

      will_listen() {
        [ "${1:-}" = "web" ] && return 0
        [ "${1:-}" = "--profile" ] && [ "${2:-}" = "web" ] && return 0
        return 1
      }
      # OHOS sandbox hides the process from ps/netstat; probe the listen port.
      # (-f: fail fast on HTTP errors so the exit code doubles as "is 200".)
      is_running() {
        curl -sf -o /dev/null -m2 "http://127.0.0.1:$PORT/" 2>/dev/null
      }
      if will_listen "$@" && is_running; then
        echo "dsh: already running at http://127.0.0.1:$PORT (stop it or use another profile)" >&2
        exit 0
      fi

      exec "$SHIM" "$NODE" --expose-internals "$DSH_BIN" "$@"
    SH
    chmod 0755, bin/"dsh"
  end

  def caveats
    <<~EOS
      dsh (DeepSeek Harness) needs model credentials — configure per the
      upstream docs (https://github.com/deepseek-ai/deepseek-harness), typically
      under ~/.dsh/ (dsh writes its profile tree there on first run).

      Web UI:   dsh web                       (http://127.0.0.1:3080)
      One-shot: dsh --profile headless "..."
      Profiles: dsh --profile <name> --help

      OHOS notes (handled by this formula): ohos-compat-shim covers OHOS's
      global hard-link ban (session persistence .tmp->atomics) and the
      os.userInfo() ENOENT quirk; a bundled stub neutralizes the Win32-only
      koffi import; node runs with --expose-internals for HMR.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dsh -V")
  end
end
