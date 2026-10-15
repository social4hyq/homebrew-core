class ClaudeCodeLatest < Formula
  desc "Anthropic Claude Code CLI (latest release channel)"
  homepage "https://code.claude.com/docs/en/overview"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-2.1.300.tgz"
  sha256 "9fc567977a0f445cb15f8f5d038c3d0e3ef49a8644c6b10aa050cbabefa6bb25"
  license :cannot_represent # Anthropic Legal Agreements (Commercial ToS)
  revision 3

  livecheck do
    url "https://downloads.claude.ai/claude-code-releases/latest"
    regex(/(\d+(?:\.\d+)+)/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code.latest-v2.1.300-r4"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a079926c7035db09c9bab025e50c3cfe9dd5df8ea2f03cae7feec86ebaf54c3b"
  end

  depends_on "node"
  depends_on "ohos-compat-shim"
  depends_on "ohos-selfsign"

  conflicts_with "claude-code", because: "both install the `claude` binary"

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
            --ignore-scripts --loglevel=error --fetch-retries=5 "@anthropic-ai/claude-code-linux-arm64-musl@#{version}" >&2
          PKG="$TMP/node_modules/@anthropic-ai/claude-code-linux-arm64-musl/claude"
          "$HOMEBREW_PREFIX/opt/ohos-selfsign/bin/selfsign" "$PKG"
          mkdir -p "${BIN%/*}" && mv "$PKG" "$BIN.part" && mv "$BIN.part" "$BIN"
          rm -rf "$TMP" # the final exec skips the EXIT trap
        fi
        [ -z "$HELD" ] || rm -rf "$LOCK"
      fi
      exec "$HOMEBREW_PREFIX/opt/ohos-compat-shim/bin/ohos-shim" "$BIN" "$@"
    SH
    chmod 0755, bin/"claude"
  end

  test do
    assert_match "#{version} (Claude Code)", shell_output("#{bin}/claude --version")
  end
end
