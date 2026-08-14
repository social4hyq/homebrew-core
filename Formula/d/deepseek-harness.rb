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

  depends_on "node"

  def install
    cd buildpath do
      ENV["npm_config_cache"] = (HOMEBREW_CACHE/"deepseek-harness-npm-cache").to_s
      npm = formula_opt_bin("node")/"npm"
      # --ignore-scripts blocks native postinstalls (koffi's build fails on
      # OHOS; the stub below makes it dead code). Platform gating under
      # process.platform=openharmony skips every os:["linux"] optional binary;
      # sharp falls back to wasm (added here), esbuild to its openharmony pkg.
      system npm, "install", "--ignore-scripts", "--no-audit", "--no-fund", "@img/sharp-wasm32"
      system npm, "rebuild", "node-pty"
      # dsh-sandbox-local unconditionally static-imports this Win32-only ACL
      # module, which static-imports koffi. All its symbols are Win32 dead
      # code on Linux/OHOS (File.write overwrites; Pathname#write refuses to).
      File.write("node_modules/@deepseek-ai/dsh-sandbox-windows-acl/lib/index.js", <<~JS)
        export const AclWriteGrant = undefined;
        export const assertTempRootOutsideWorkspace = () => {};
        export const tempWriteSid = () => undefined;
        export const workspaceWriteSid = () => undefined;
        export {};
      JS
      File.write("ohos-preload.cjs", <<~JS)
        // OHOS fallbacks for bare node; see deepseek-harness formula.
        "use strict";
        const os = require("node:os");
        const fs = require("node:fs");
        const fsp = fs.promises;

        const origUserInfo = os.userInfo.bind(os);
        os.userInfo = function userInfo(...args) {
          try {
            return origUserInfo(...args);
          } catch (e) {
            if (!/ENOENT/.test(String(e?.message ?? e))) throw e;
            return {
              uid: process.getuid?.() ?? -1,
              gid: process.getgid?.() ?? -1,
              username: process.env.USER || process.env.LOGNAME || "user",
              homedir: os.homedir(),
              shell: process.env.SHELL || "/bin/sh",
            };
          }
        };

        const linkFallback = (e) => e?.code === "EPERM" || e?.code === "EACCES" || e?.code === "EOPNOTSUPP";

        const origLinkSync = fs.linkSync.bind(fs);
        fs.linkSync = function linkSync(src, dest) {
          try {
            return origLinkSync(src, dest);
          } catch (e) {
            if (!linkFallback(e)) throw e;
            const { mode } = fs.statSync(src);
            const fd = fs.openSync(dest, "wx", mode);
            try {
              fs.writeFileSync(fd, fs.readFileSync(src));
            } finally {
              fs.closeSync(fd);
            }
          }
        };

        const origLink = fsp.link.bind(fsp);
        fsp.link = async function link(src, dest) {
          try {
            return await origLink(src, dest);
          } catch (e) {
            if (!linkFallback(e)) throw e;
            const { mode } = await fsp.stat(src);
            const fh = await fsp.open(dest, "wx", mode);
            try {
              await fh.writeFile(await fsp.readFile(src));
            } finally {
              await fh.close();
            }
          }
        };
      JS
      rm "package-lock.json"
      libexec.install Dir["*"]
    end

    # bin/dsh wrapper: node --require preload (OHOS fallbacks) +
    # --expose-internals (HMR; cannot go in NODE_OPTIONS). Runtime
    # $HOMEBREW_PREFIX only — relocatable (same rationale as claude-code.rb).
    (bin/"dsh").write <<~SH
      #!/bin/sh
      set -eu
      HB="${HOMEBREW_PREFIX:-$HOME/.harmonybrew}"
      NODE="$HB/opt/node/bin/node"
      PRELOAD="$HB/opt/#{name}/libexec/ohos-preload.cjs"
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

      exec "$NODE" --require "$PRELOAD" --expose-internals "$DSH_BIN" "$@"
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

      OHOS notes (handled by this formula): a bundled preload patches
      os.userInfo() and fs.link() fallbacks; a stub neutralizes the Win32-only
      koffi import; node runs with --expose-internals for HMR.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dsh -V")
  end
end
