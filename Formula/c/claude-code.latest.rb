class ClaudeCodeLatest < Formula
  desc "Anthropic Claude Code CLI (latest release channel)"
  homepage "https://code.claude.com/docs/en/overview"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-2.1.275.tgz"
  sha256 "506ba2bb8336d0055eb04126fb0fb5023d95d900fc45913d40a1a5048b5908a9"
  license :cannot_represent # Anthropic Legal Agreements (Commercial ToS)
  # Anthropic License forbids redistributing the official artifacts, so this is
  # a runtime-fetch stub: install() ships only a wrapper. It runs the official
  # binary directly (self-signed with ohos-bst-light, launched through
  # ohos-compat-shim's ohos-shim) so it can follow the latest channel, including
  # releases that need Anthropic's private bun internals; the stable channel is
  # the separate claude-code formula.
  #
  # npmmirror: brew's curl SIGILLs on the Cloudflare-fronted registry.npmjs.org.

  livecheck do
    url "https://downloads.claude.ai/claude-code-releases/latest"
    regex(/(\d+(?:\.\d+)+)/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code.latest-v2.1.274-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e63fd20001e251f3e356864e7fd30f04055f1a6b7e109f7ae7fa537d087f23e5"
  end

  depends_on "ohos-bst-light"
  depends_on "ohos-compat-shim"

  conflicts_with "claude-code", because: "both install the `claude` binary"

  def install
    # Homebrew's build step auto-installs README/LICENSE metafiles from the
    # staged tarball into the keg; drop them so the bottle carries no bytes of
    # the official artifact (Anthropic License: all rights reserved).
    require "metafiles"
    buildpath.children.each { |p| p.unlink if p.file? && Metafiles.copy?(p.basename.to_s) }

    (bin/"claude").write <<~SH
      #!/bin/sh
      set -e
      : "${HOMEBREW_PREFIX:?claude-code.latest: HOMEBREW_PREFIX not set; run 'brew shellenv' first}"
      HB="$HOMEBREW_PREFIX"
      VER="#{version}"
      CACHE="${CLAUDE_CODE_CACHE:-${HOMEBREW_CACHE:-$HOME/.cache/homebrew}/claude-code.latest/$VER}"
      BIN="$CACHE/claude"

      # /tmp is read-only here; the CLI needs a writable scratch dir.
      if [ -z "${CLAUDE_CODE_TMPDIR:-}" ] && [ -w /data/storage/el2/base/tmp ]; then
        export CLAUDE_CODE_TMPDIR=/data/storage/el2/base/tmp
      fi

      if [ ! -x "$BIN" ]; then
        rm -rf "$CACHE"
        mkdir -p "$CACHE"
        TMP="$(mktemp -d)"
        trap 'rm -rf "$TMP"' EXIT
        echo "claude-code.latest: fetching official binary $VER..." >&2
        for u in "#{stable.url}" "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-$VER.tgz"; do
          curl -fsSL --retry 3 --retry-all-errors --retry-delay 2 "$u" -o "$TMP/pkg.tgz" && break
        done
        printf '%s  %s\\n' "#{stable.checksum}" "$TMP/pkg.tgz" | sha256sum -c -
        tar -xzf "$TMP/pkg.tgz" -C "$TMP"
        "$HB/opt/ohos-bst-light/bin/selfsign" "$TMP/package/claude"
        mv "$TMP/package/claude" "$BIN"
        chmod 0755 "$BIN"
      fi

      exec "$HB/opt/ohos-compat-shim/bin/ohos-shim" "$BIN" "$@"
    SH
    chmod 0755, bin/"claude"
  end

  test do
    assert_match "#{version} (Claude Code)", shell_output("#{bin}/claude --version")

    # --version never touches the renderer; start the real TUI under a pty and
    # fail on the startup crash signature.
    tui = shell_output("timeout 10 script -q -c '#{bin}/claude' /dev/null 2>&1; true")
    refute_includes tui, "Uncaught exception", "claude's TUI crash-looped at startup"
  end
end
