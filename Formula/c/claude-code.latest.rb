class ClaudeCodeLatest < Formula
  desc "Anthropic Claude Code CLI (latest release channel)"
  homepage "https://code.claude.com/docs/en/overview"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-2.1.294.tgz"
  sha256 "1a4ccf2f83c155be1f4516e698c37e17799835d9a06c6a83f687af22e63a722f"
  license :cannot_represent # Anthropic Legal Agreements (Commercial ToS)

  livecheck do
    url "https://downloads.claude.ai/claude-code-releases/latest"
    regex(/(\d+(?:\.\d+)+)/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code.latest-v2.1.294-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5f4f6d41b8c1093a986dcf35d23da6a491c8f83453e2707ace327cecb6ec1a56"
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
          curl -fL# --retry 3 "#{stable.url}" -o "$TMP/pkg.tgz"
          echo "#{stable.checksum}  $TMP/pkg.tgz" | sha256sum -c - >/dev/null
          tar -xzf "$TMP/pkg.tgz" -C "$TMP"
          "$HOMEBREW_PREFIX/opt/ohos-selfsign/bin/selfsign" "$TMP/package/claude"
          mkdir -p "${BIN%/*}" && mv "$TMP/package/claude" "$BIN.part" && mv "$BIN.part" "$BIN"
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
