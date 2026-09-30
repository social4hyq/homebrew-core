class ClaudeCodeLatest < Formula
  desc "Anthropic Claude Code CLI (latest release channel)"
  homepage "https://code.claude.com/docs/en/overview"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-2.1.285.tgz"
  sha256 "5c0017d0e0b9518417dfbf419d04d20c7637ee885600a63ea041e0ff57e4b0eb"
  license :cannot_represent # Anthropic Legal Agreements (Commercial ToS)
  revision 1

  livecheck do
    url "https://downloads.claude.ai/claude-code-releases/latest"
    regex(/(\d+(?:\.\d+)+)/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code.latest-v2.1.285-r2"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a66392b5dd48fbc61662b1d79cc7c7ddab440a1df17c70f03c5cc45f20500c05"
  end

  depends_on "ohos-compat-shim"
  depends_on "ohos-selfsign"

  conflicts_with "claude-code", because: "both install the `claude` binary"

  def install
    (bin/"claude").write <<~SH
      #!/bin/sh
      set -eu
      export CLAUDE_CODE_TMPDIR="${CLAUDE_CODE_TMPDIR:-/data/storage/el2/base/cache}"
      BIN="${HOMEBREW_CACHE:-$HOME/.cache/homebrew}/#{name}/#{version}/claude"
      if [ ! -x "$BIN" ]; then
        TMP="$(mktemp -d -p "$CLAUDE_CODE_TMPDIR")" && trap 'rm -rf "$TMP"' EXIT
        curl -fsSL --retry 3 "#{stable.url}" -o "$TMP/pkg.tgz"
        echo "#{stable.checksum}  $TMP/pkg.tgz" | sha256sum -c - >/dev/null
        tar -xzf "$TMP/pkg.tgz" -C "$TMP"
        "$HOMEBREW_PREFIX/opt/ohos-selfsign/bin/selfsign" "$TMP/package/claude"
        mkdir -p "${BIN%/*}" && mv "$TMP/package/claude" "$BIN"
      fi
      exec "$HOMEBREW_PREFIX/opt/ohos-compat-shim/bin/ohos-shim" "$BIN" "$@"
    SH
    chmod 0755, bin/"claude"
  end

  test do
    assert_match "#{version} (Claude Code)", shell_output("#{bin}/claude --version")
  end
end
