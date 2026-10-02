class ClaudeCodeLatest < Formula
  desc "Anthropic Claude Code CLI (latest release channel)"
  homepage "https://code.claude.com/docs/en/overview"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-2.1.287.tgz"
  sha256 "4e47275d0796c0456aa1563a18122fd8f7bac725efcf0e1f197c98d4ed9c9322"
  license :cannot_represent # Anthropic Legal Agreements (Commercial ToS)

  livecheck do
    url "https://downloads.claude.ai/claude-code-releases/latest"
    regex(/(\d+(?:\.\d+)+)/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code.latest-v2.1.287-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "88cbe38c50c6634fedecb6004dab7d9b22feca6144b30ccf61808a6256bd9d90"
  end

  depends_on "ohos-compat-shim"
  depends_on "ohos-selfsign"

  conflicts_with "claude-code", because: "both install the `claude` binary"

  def install
    rm_r buildpath.children # keep the official README/LICENSE out of the bottle
    (bin/"claude").write <<~SH
      #!/bin/sh
      set -eu
      export CLAUDE_CODE_TMPDIR="${CLAUDE_CODE_TMPDIR:-/data/storage/el2/base/cache}"
      BIN="${HOMEBREW_CACHE:-$HOME/.cache/homebrew}/#{name}/#{version}/claude"
      if [ ! -x "$BIN" ]; then
        echo "First run: downloading Claude Code #{version} (~230 MB), one-time setup..." >&2
        TMP="$(mktemp -d -p "$CLAUDE_CODE_TMPDIR")" && trap 'rm -rf "$TMP"' EXIT
        curl -fL# --retry 3 "#{stable.url}" -o "$TMP/pkg.tgz"
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
