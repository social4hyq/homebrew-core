class ClaudeCodeLatest < Formula
  desc "Anthropic Claude Code CLI (latest release channel)"
  homepage "https://code.claude.com/docs/en/overview"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-2.1.273.tgz"
  sha256 "a32d187b109980991b9f5f3f6630e34575e54df8a0773f2a68ce540bac85fe55"
  license :cannot_represent # Anthropic Commercial Terms of Service
  # Latest release channel. Anthropic License prohibits redistributing the
  # official artifacts, so install() ships only a wrapper: the official tarball
  # is fetched, sha256-checked, self-signed (ohos-bst-light) and cached at first
  # run. It runs the official binary directly through ohos-compat-shim's
  # ohos-shim (its embedded bun needs the shim's OHOS workarounds), the only way
  # to follow releases that use Anthropic's private bun internals (2.1.272 added
  # Bun.ant.CellSegmenter); the stable track instead runs the extracted CLI
  # bundle on this tap's OHOS-fixed bun (claude-code).
  #
  # npmmirror: brew's curl SIGILLs on the Cloudflare-fronted registry.npmjs.org;
  # the mirror avoids it. sha256 is verified regardless of source.
  #
  # Wrapper uses runtime $HOMEBREW_PREFIX only.

  livecheck do
    # Anthropic's latest release channel (plain-text version pointer).

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code.latest-v2.1.273-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "723769f620ff42a0c07a87b9f33569e731093b7ab677ac7d3b427f359062959c"
  end
    url "https://downloads.claude.ai/claude-code-releases/latest"
    regex(/(\d+(?:\.\d+)+)/i)
  end

  depends_on "ohos-bst-light"
  depends_on "ohos-compat-shim"

  def install
    (bin/"claude").write <<~SH
      #!/bin/sh
      set -e
      : "${HOMEBREW_PREFIX:?claude-code.latest: HOMEBREW_PREFIX not set; run 'brew shellenv' first}"
      HB="$HOMEBREW_PREFIX"
      VER="#{version}"
      NPM_URL="#{stable.url}"
      NPM_SHA="#{stable.checksum}"
      CACHE="${CLAUDE_CODE_CACHE:-${HOMEBREW_CACHE:-$HOME/.cache/homebrew}/claude-code.latest/$VER}"
      BIN="$CACHE/claude"

      # /tmp is read-only here, so hand the CLI a writable scratch dir of its
      # own. A caller-set value wins; an unusable fallback is left unset rather
      # than failing the wrapper.
      if [ -z "${CLAUDE_CODE_TMPDIR:-}" ] && [ -w /data/storage/el2/base/tmp ]; then
        export CLAUDE_CODE_TMPDIR=/data/storage/el2/base/tmp
      fi

      if [ ! -x "$BIN" ]; then
        rm -rf "$CACHE"
        mkdir -p "$CACHE"
        TMP="$(mktemp -d)"
        trap 'rm -rf "$TMP"' EXIT
        echo "claude-code.latest: fetching official binary $VER..." >&2
        FALLBACK="https://registry.npmjs.org/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-$VER.tgz"
        fetched=0
        for u in "$NPM_URL" "$FALLBACK"; do
          curl -fsSL --retry 3 --retry-all-errors --retry-delay 2 "$u" -o "$TMP/pkg.tgz" && { fetched=1; break; }
        done
        [ "$fetched" = 1 ] || { echo "claude-code.latest: download failed from all mirrors" >&2; exit 1; }
        # Fail closed: an unverified runtime download must never be trusted.
        command -v sha256sum >/dev/null 2>&1 || {
          echo "claude-code.latest: sha256sum not found; refusing an unverified download" >&2
          exit 1
        }
        printf '%s  %s\\n' "$NPM_SHA" "$TMP/pkg.tgz" | sha256sum -c -
        tar -xzf "$TMP/pkg.tgz" -C "$TMP"
        SRC="$TMP/package/claude"
        [ -f "$SRC" ] || { echo "claude-code.latest: 'claude' binary not found in tarball" >&2; exit 1; }
        "$HB/opt/ohos-bst-light/bin/selfsign" "$SRC"
        mv "$SRC" "$BIN"
        chmod 0755 "$BIN"
      fi

      exec "$HB/opt/ohos-compat-shim/bin/ohos-shim" "$BIN" "$@"
    SH
    chmod 0755, bin/"claude"
  end

  def caveats
    <<~EOS
      claude-code.latest follows the latest release channel and runs the official
      compiled binary directly — nothing of the official release is in the bottle
      (Anthropic License). The first `claude` invocation downloads the official
      tarball (via the npmmirror mirror), verifies its sha256, self-signs it
      (ohos-bst-light) and caches it under
      $HOMEBREW_CACHE/claude-code.latest/#{version}/ (override with CLAUDE_CODE_CACHE).
      It is launched through ohos-compat-shim's ohos-shim.

      Installing claude-code.latest links the same `claude` binary as claude-code;
      keep only one of the two installed.

      Claude Code requires API credentials. Configure via environment variables:

        export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
        export ANTHROPIC_AUTH_TOKEN=sk-xxx
        export ANTHROPIC_MODEL=deepseek-v4-flash
        export ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-flash
        export ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-flash
        export ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
        export CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
        export CLAUDE_CODE_EFFORT_LEVEL=max

      See https://api-docs.deepseek.com/zh-cn/quick_start/agent_integrations/claude_code
      for DeepSeek integration details.

      For OpenAI-format APIs, install claude-code-router:
        brew install claude-code-router
    EOS
  end

  test do
    # End-to-end: wrapper runtime-fetches, sha256-verifies, self-signs and runs
    # the official binary under ohos-compat-shim. The version must come out of
    # that binary. First run downloads the ~100MB tgz from npmmirror.
    assert_match "#{version} (Claude Code)", shell_output("#{bin}/claude --version")
  end
end
