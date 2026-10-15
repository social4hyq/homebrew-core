class ClaudeCode < Formula
  desc "Anthropic Claude Code CLI"
  homepage "https://code.claude.com/docs/en/overview"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64/-/claude-code-linux-arm64-2.1.292.tgz"
  sha256 "763250852824215ac3b02a5985688a742a243899ef689dd66c5b99a01f270003"
  license :cannot_represent # Anthropic Legal Agreements (Commercial ToS)
  revision 4

  livecheck do
    url "https://downloads.claude.ai/claude-code-releases/stable"
    regex(/(\d+(?:\.\d+)+)/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code-v2.1.292-r4"
    rebuild 2
    sha256 cellar: :any_skip_relocation, arm64_ohos: "19225b4111164475957b6e0e236717b795efbd9f4040f60dee4be4649e53cbe3"
  end

  depends_on "glibc"
  depends_on "node"
  depends_on "ohos-compat-shim"
  depends_on "ohos-selfsign"
  depends_on "patchelf"

  conflicts_with "claude-code.latest", because: "both install the `claude` binary"

  def install
    rm_r buildpath.children # keep the official README/LICENSE out of the bottle
    (bin/"claude").write <<~SH
      #!/bin/sh
      set -eu
      export CLAUDE_CODE_TMPDIR="${CLAUDE_CODE_TMPDIR:-/data/storage/el2/base/cache}"
      BIN="${HOMEBREW_CACHE:-$HOME/.cache/homebrew}/#{name}/#{pkg_version}/claude"
      if [ ! -x "$BIN" ]; then
        LOCK="${BIN%/*}.lock"
        HELD="" TMP=""
        trap '[ -z "$HELD" ] || rm -rf "$LOCK"; [ -z "$TMP" ] || rm -rf "$TMP"' EXIT
        mkdir -p "${LOCK%/*}"
        [ ! -d "$LOCK" ] || echo "Another claude is installing #{version}, waiting..." >&2
        until mkdir "$LOCK" 2>/dev/null && HELD=1; do
          [ -x "$BIN" ] && break
          OWNER="$(cat "$LOCK/pid" 2>/dev/null || true)"
          if [ -n "$OWNER" ] && ! kill -0 "$OWNER" 2>/dev/null; then rm -rf "$LOCK"; fi
          sleep 1
        done
        if [ -n "$HELD" ] && [ ! -x "$BIN" ]; then
          echo $$ > "$LOCK/pid"
          echo "First run: downloading Claude Code #{version} (~230 MB), one-time setup..." >&2
          TMP="$(mktemp -d -p "$CLAUDE_CODE_TMPDIR")"
          PATH="$HOMEBREW_PREFIX/opt/node/bin:$PATH" npm install --prefix "$TMP" --force --no-save --no-audit --no-fund \
            --ignore-scripts --loglevel=error --fetch-retries=5 "@anthropic-ai/claude-code-linux-arm64@#{version}" >&2
          PKG="$TMP/node_modules/@anthropic-ai/claude-code-linux-arm64/claude"
          "$HOMEBREW_PREFIX/opt/patchelf/bin/patchelf" \
            --set-interpreter "$HOMEBREW_PREFIX/opt/glibc/lib/ld-linux-aarch64.so.1" "$PKG"
          "$HOMEBREW_PREFIX/opt/ohos-selfsign/bin/selfsign" "$PKG"
          mkdir -p "${BIN%/*}" && mv "$PKG" "$BIN.part" && mv "$BIN.part" "$BIN"
          rm -rf "$TMP" # the final exec skips the EXIT trap
        fi
        [ -z "$HELD" ] || rm -rf "$LOCK"
      fi
      SHIM="$HOMEBREW_PREFIX/opt/ohos-compat-shim/lib/libohos_compat_glibc.so"
      if [ -f "$SHIM" ]; then
        export LD_PRELOAD="$SHIM"
      else
        unset LD_PRELOAD
        echo "claude: $SHIM not found (needs ohos-compat-shim >= 0.8.0), idle CPU will be high" >&2
      fi
      exec "$BIN" "$@"
    SH
    chmod 0755, bin/"claude"
  end

  test do
    assert_match "#{version} (Claude Code)", shell_output("#{bin}/claude --version")
  end
end
