class DeepseekHarness < Formula
  desc "DeepSeek coding agent with web, TUI and headless profiles"
  homepage "https://github.com/deepseek-ai/deepseek-harness"
  url "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-0.1.0-rc.6.tgz"
  sha256 "1b8a9a0ad3c7feaece47926e0bd37ca151c7ccfa997953afa5fd01261784eadc"
  license "MIT"
  revision 1

  livecheck do
    url "https://registry.npmjs.org/@deepseek-ai/dsh/latest"
    regex(/"version":\s*"([^"]+)"/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/deepseek-harness-v0.1.0-rc.6-r4"
    rebuild 2
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7bf765f85c4216b15f4415a1bd76a6c74eaaa876a7a07815848156b46c013d07"
  end

  depends_on "node"

  def install
    # ~/.npm is unwritable inside build sandboxes.
    ENV["npm_config_cache"] = (HOMEBREW_CACHE/"deepseek-harness-npm-cache").to_s

    # --ignore-scripts: koffi cannot build on OHOS (its only import site is
    # stubbed out below) and node-pty is rebuilt separately. On openharmony
    # npm skips every os:["linux"] optional binary, so install sharp's wasm
    # fallback explicitly. prefix: false keeps node_modules in buildpath.
    system "npm", "install", *std_npm_args(prefix: false), "--no-audit", "--no-fund", "@img/sharp-wasm32"

    system "npm", "rebuild", "node-pty"

    # dsh-sandbox-local static-imports this Win32-only module, which is the
    # only reason koffi is in the tree. File.write overwrites; Pathname#write
    # refuses to overwrite an existing file.
    File.write("node_modules/@deepseek-ai/dsh-sandbox-windows-acl/lib/index.js", <<~JS)
      export const AclWriteGrant = undefined;
      export const assertTempRootOutsideWorkspace = () => {};
      export const tempWriteSid = () => undefined;
      export const workspaceWriteSid = () => undefined;
      export {};
    JS

    # os.userInfo() ENOENT and fs.link() EPERM fallbacks, loaded via
    # `node --require` by the bin wrapper below.
    (buildpath/"ohos-preload.cjs").write <<~JS
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

    # Wrapper: --require preload (OHOS fallbacks) + --expose-internals (HMR).
    (bin/"dsh").write <<~SH
      #!/bin/sh
      set -eu
      : "${HOMEBREW_PREFIX:?dsh: HOMEBREW_PREFIX not set; run 'brew shellenv' first}"
      HB="$HOMEBREW_PREFIX"
      DSH="$HB/opt/#{name}/libexec"
      PORT=3080

      will_listen() { [ "${1:-}" = web ] || { [ "${1:-}" = --profile ] && [ "${2:-}" = web ]; }; }
      # OHOS hides listeners from ps/netstat; probe the port instead.
      is_running() { curl -sf -o /dev/null -m2 "http://127.0.0.1:$PORT/" 2>/dev/null; }
      if will_listen "$@" && is_running; then
        echo "dsh: already running at http://127.0.0.1:$PORT (stop it or use another profile)" >&2
        exit 0
      fi

      exec "$HB/opt/node/bin/node" --require "$DSH/ohos-preload.cjs" --expose-internals "$DSH/lib/bin.js" "$@"
    SH
    chmod 0755, bin/"dsh"
  end

  def caveats
    <<~EOS
      dsh needs model credentials before first use; see the upstream docs
      (https://github.com/deepseek-ai/deepseek-harness). Profiles and config
      are written under ~/.dsh/ on first run.

      Web UI:   dsh web                       (http://127.0.0.1:3080)
      One-shot: dsh --profile headless "..."
      Profiles: dsh --profile <name> --help
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dsh -V")
    assert_match "Usage:", shell_output("#{bin}/dsh --help")
  end
end
