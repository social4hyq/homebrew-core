class ClaudeCodeLatest < Formula
  desc "Anthropic Claude Code CLI (latest release channel)"
  homepage "https://code.claude.com/docs/en/overview"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64/-/claude-code-linux-arm64-2.1.300.tgz"
  sha256 "10d8c7045093d74b35238daf2a19eef16465d99eb6f8ac7e9eeaa2aee917fb29"
  license :cannot_represent # Anthropic Legal Agreements (Commercial ToS)
  revision 1

  livecheck do
    url "https://downloads.claude.ai/claude-code-releases/latest"
    regex(/(\d+(?:\.\d+)+)/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code.latest-v2.1.300-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d7dab6058aba20e7783194366afe8f58a59d4c9871cf74597a12a12b41f219d2"
  end

  depends_on "glibc"
  depends_on "ohos-selfsign"
  depends_on "patchelf"

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
          curl -fL# --retry 3 "#{stable.url}" -o "$TMP/pkg.tgz"
          echo "#{stable.checksum}  $TMP/pkg.tgz" | sha256sum -c - >/dev/null
          tar -xzf "$TMP/pkg.tgz" -C "$TMP"
          "$HOMEBREW_PREFIX/opt/patchelf/bin/patchelf" \
            --set-interpreter "$HOMEBREW_PREFIX/opt/glibc/lib/ld-linux-aarch64.so.1" "$TMP/package/claude"
          "$HOMEBREW_PREFIX/opt/ohos-selfsign/bin/selfsign" "$TMP/package/claude"
          mkdir -p "${BIN%/*}" && mv "$TMP/package/claude" "$BIN.part" && mv "$BIN.part" "$BIN"
        fi
        [ -z "$HELD" ] || rm -rf "$LOCK"
      fi
      unset LD_PRELOAD
      exec "$BIN" "$@"
    SH
    chmod 0755, bin/"claude"
  end

  test do
    assert_match "#{version} (Claude Code)", shell_output("#{bin}/claude --version")
  end
end
