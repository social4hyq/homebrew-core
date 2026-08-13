class ClaudeCode < Formula
  desc "Anthropic Claude Code CLI — HarmonyOS (runtime-fetch stub; no binary in bottle)"
  homepage "https://code.claude.com/docs/en/overview"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-2.1.228.tgz"
  sha256 "535e6daa6256689803cef88620e940924d00d274c2c293efe4a33590c2718cc9"
  license :cannot_represent # Anthropic Commercial Terms of Service
  revision 1
  # Stub bottle: Anthropic License forbids redistribution, so install() ships
  # only a wrapper that fetches + sha256-checks + self-signs the binary at first
  # run (binary-sign-tool corrupts it → ohos-bst-light self-sign instead).
  # npmmirror mirror: brew's curl SIGILLs on the Cloudflare-fronted npmjs.org.

  livecheck do
    # www.npmjs.com 403s from this env; registry API JSON is reachable.
    # Same npmmirror livecheck pattern used elsewhere in this tap.
    url "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-arm64-musl/latest"
    regex(/"version":\s*"(\d+(?:\.\d+)+)"/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code-v2.1.228-r3"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c825ca5944d5a774d41bfc14aa6b92fbbe9ac7f7d50203c088ba801d345878a9"
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

      export CLAUDE_CODE_TMPDIR="${CLAUDE_CODE_TMPDIR:-/data/storage/el2/base/cache}"
      exec "$HB/opt/ohos-compat-shim/bin/ohos-shim" "$BIN" "$@"
    SH
    chmod 0755, bin/"claude"
  end

  def caveats
    <<~EOS
      claude-code is a runtime-fetch stub: the official binary is NOT in the
      bottle (Anthropic License). The first `claude` invocation downloads it,
      self-signs it, and caches it under $HOMEBREW_CACHE/claude-code/#{version}/
      (override with CLAUDE_CODE_CACHE).

      Claude Code requires API credentials; see the Anthropic Claude Code docs.
    EOS
  end

  test do
    # Assert stub only — `claude --version` would trigger the runtime fetch during `brew test`.
    assert_path_exists bin/"claude"
  end
end
