class ClaudeCode < Formula
  desc "Anthropic Claude Code CLI"
  homepage "https://code.claude.com/docs/en/overview"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-2.1.228.tgz"
  sha256 "535e6daa6256689803cef88620e940924d00d274c2c293efe4a33590c2718cc9"
  license :cannot_represent # Anthropic Commercial Terms of Service
  revision 3
  # npmmirror mirror: brew's curl SIGILLs on the Cloudflare-fronted registry.npmjs.org
  # (aarch64 SIMD AES path trapped by kernel); npmmirror (Aliyun CDN) doesn't.
  # Files are byte-identical (sha256 matches); wrapper tries npmmirror first,
  # falls back to registry.npmjs.org for non-buggy curl or mirror lag.
  #
  # Stub bottle: Anthropic License prohibits redistributing the official binary,
  # so install() writes only a wrapper — the binary is fetched, sha256-checked,
  # and self-signed (ohos-bst-light) at first run: binary-sign-tool corrupts the
  # embedded app and it degenerates to bare bun runtime.
  # pour_bottle? also bypasses Homebrew's DevelopmentTools requirement
  # (OHOS ships no /usr/bin/clang).
  #
  # Relocatability: wrapper uses runtime $HOMEBREW_PREFIX only — no build-time path interpolation.

  livecheck do
    # www.npmjs.com 403s from this env; registry API JSON is reachable.
    # Same npmmirror livecheck pattern used elsewhere in this tap.
    url "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-arm64-musl/latest"
    regex(/"version":\s*"(\d+(?:\.\d+)+)"/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code-v2.1.228-r6"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e1f9b711d9c4692f07b201193063f51bceab324268dd78ee91d1a92208792832"
  end

  depends_on "ohos-bst-light"
  depends_on "ohos-compat-shim"

  def install
    # install() never references the official binary — only the stub goes in the bottle.
    (bin/"claude").write <<~SH
      #!/bin/sh
      set -e
      : "${HOMEBREW_PREFIX:?claude-code: HOMEBREW_PREFIX not set; run 'brew shellenv' first}"
      HB="$HOMEBREW_PREFIX"
      VER="#{version}"
      NPM_URL="#{stable.url}"
      NPM_SHA="#{stable.checksum}"
      CACHE="${CLAUDE_CODE_CACHE:-${HOMEBREW_CACHE:-$HOME/.cache/homebrew}/claude-code/$VER}"
      BIN="$CACHE/claude"

      if [ ! -x "$BIN" ]; then
        mkdir -p "$CACHE"
        TMP="$(mktemp -d)"
        trap 'rm -rf "$TMP"' EXIT
        echo "claude-code: fetching official binary $VER..." >&2
        # npmmirror primary (curl SIGILL on Cloudflare); sha256 verifies regardless of source.
        FALLBACK="https://registry.npmjs.org/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-$VER.tgz"
        fetched=0
        for u in "$NPM_URL" "$FALLBACK"; do
          curl -fL "$u" -o "$TMP/pkg.tgz" && { fetched=1; break; }
        done
        [ "$fetched" = 1 ] || { echo "claude-code: download failed from all mirrors" >&2; exit 1; }
        # Fail closed: an unverified runtime-downloaded executable must never run.
        command -v sha256sum >/dev/null 2>&1 || {
          echo "claude-code: sha256sum not found; refusing to run an unverified download" >&2
          exit 1
        }
        printf '%s  %s\\n' "$NPM_SHA" "$TMP/pkg.tgz" | sha256sum -c -
        tar -xzf "$TMP/pkg.tgz" -C "$TMP"
        SRC="$TMP/package/claude"
        [ -f "$SRC" ] || SRC="$(find "$TMP" -type f -name claude | head -n1)"
        [ -f "$SRC" ] || { echo "claude-code: 'claude' binary not found in tarball" >&2; exit 1; }
        "$HB/opt/ohos-bst-light/bin/self-sign" "$SRC"
        mv "$SRC" "$BIN"
        chmod 0755 "$BIN"
      fi

      exec "$HB/opt/ohos-compat-shim/bin/ohos-shim" "$BIN" "$@"
    SH
    chmod 0755, bin/"claude"
  end

  def caveats
    <<~EOS
      claude-code is installed as a runtime-fetch stub: the official binary is
      NOT in the bottle (Anthropic License). The first `claude` invocation
      downloads it (via the npmmirror mirror), self-signs it, and caches it under
      $HOMEBREW_CACHE/claude-code/#{version}/ (override with CLAUDE_CODE_CACHE).

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
    # Assert stub only — `claude --version` would trigger the runtime fetch during `brew test`.
    assert_path_exists bin/"claude"
  end
end
