class ClaudeCode < Formula
  desc "Anthropic Claude Code CLI"
  homepage "https://code.claude.com/docs/en/overview"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-2.1.280.tgz"
  sha256 "c97dd11f2cfdaa0d5ee17cfd3fac28310bf137541de2c577c40094131697f534"
  license :cannot_represent # Anthropic Legal Agreements (Commercial ToS)
  revision 1

  livecheck do
    url "https://downloads.claude.ai/claude-code-releases/stable"
    regex(/(\d+(?:\.\d+)+)/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code-v2.1.280-r2"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5bb578965ae2f4d91e21a7865c29531c63a795f2c706482281a527402d18616b"
  end

  depends_on "ohos-compat-shim"
  depends_on "ohos-selfsign"

  conflicts_with "claude-code.latest", because: "both install the `claude` binary"

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
