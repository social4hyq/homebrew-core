class ClaudeCode < Formula
  desc "Anthropic Claude Code CLI — HarmonyOS (runtime-fetch stub; no binary in bottle)"
  homepage "https://docs.anthropic.com/en/docs/claude-code"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-2.1.218.tgz"
  sha256 "f2a3b0a4f4f761cc9954fd80c0b7e42fbdec187929ef9ab6bee6db348a285776"
  license :cannot_represent # Anthropic Commercial Terms of Service
  # Claude Code 2.1.113+ only ships Bun-compiled binaries (linux-arm64-musl,
  # musl ABI compatible with OHOS). The tgz is mirrored on npmmirror (Aliyun
  # CDN): brew's curl 8.21 (OpenSSL 3.6) SIGILLs on bulk TLS GET from the
  # Cloudflare-fronted registry.npmjs.org on OHOS — its aarch64 SIMD AES bulk
  # decrypt path is trapped by the kernel (verified: HEAD always succeeds, GET
  # of the ~78MB body always SIGILLs, exit 132); Aliyun's CDN does not. The
  # file is byte-identical on both (sha256 matches), so the wrapper tries
  # npmmirror first and falls back to registry.npmjs.org for non-buggy curl
  # builds or mirror lag on a freshly released version.
  #
  # Why a stub bottle: Anthropic License does not allow redistributing the
  # official binary inside a bottle, so install() writes ONLY a wrapper stub —
  # the official binary is fetched at first run, sha256-checked, self-signed
  # and cached. The bottle therefore contains just the wrapper script.
  # That also makes `pour_bottle?` true, which bypasses Homebrew's
  # DevelopmentTools requirement (formula_installer.rb:574 raises UnbottledError
  # when !pour_bottle? && !DevelopmentTools.installed?): claude-code doesn't
  # compile anything, but Homebrew demands a compiler for any bottle-less
  # formula regardless — and OHOS ships no /usr/bin/clang, so users without
  # llvm hit a "missing toolchain" error. A bottle sidesteps that entirely.
  #
  # Relocatability: the wrapper references other formulae (ohos-bst-light,
  # ohos-compat-shim) via the runtime $HOMEBREW_PREFIX env var only — NO
  # build-time path interpolation. `brew bottle` rejects HOMEBREW_PREFIX/Cellar
  # -shaped baked paths in skip_relocation bottles (opencode r0 hit this), so
  # baking the build machine's absolute prefix would odie. $HOMEBREW_PREFIX is
  # exported by Harmonybrew's `brew shellenv`, which every user is expected to
  # have eval'd.

  livecheck do
    # www.npmjs.com (the package *website*, not the registry API) 403s from
    # this environment — confirmed 2026-07-20, different host from the
    # registry.npmjs.org SIGILL issue described above (that one only bites
    # on the ~120MB tarball GET; this small registry API JSON response is
    # unaffected — confirmed reachable from the build container). Same
    # livecheck pattern used elsewhere in this tap for npmmirror-sourced
    # prebuilt-binary formulas.
    url "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-arm64-musl/latest"
    regex(/"version":\s*"(\d+(?:\.\d+)+)"/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code-v2.1.218-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a4429f81843c4d0cb2b1cc359ce5226c0cfd97c59bd9cb18728c8b85afc48718"
  end

  depends_on "ohos-bst-light"
  depends_on "ohos-compat-shim"

  def install
    # install() never downloads or references the official binary from buildpath,
    # so it cannot end up in the bottle (compliance). Only the wrapper is staged.
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
        # NPM_URL = npmmirror (primary, see top-of-file curl SIGILL note);
        # FALLBACK = registry.npmjs.org (helps non-buggy curl or mirror lag).
        # sha256 below verifies integrity regardless of which source served it.
        FALLBACK="https://registry.npmjs.org/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-$VER.tgz"
        fetched=0
        for u in "$NPM_URL" "$FALLBACK"; do
          curl -fL "$u" -o "$TMP/pkg.tgz" && { fetched=1; break; }
        done
        [ "$fetched" = 1 ] || { echo "claude-code: download failed from all mirrors" >&2; exit 1; }
        # Fail closed: this is a runtime-downloaded executable — refusing to
        # run unverified beats running unverified.
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

      export LD_PRELOAD="$HB/opt/ohos-compat-shim/lib/libohos_compat.so${LD_PRELOAD:+:$LD_PRELOAD}"
      export CLAUDE_CODE_TMPDIR="${CLAUDE_CODE_TMPDIR:-/data/storage/el2/base/cache}"
      exec "$BIN" "$@"
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
    # Don't run `claude --version` here: that would trigger the runtime fetch
    # (network + signing) during `brew test`. Just assert the stub is installed.
    assert_path_exists bin/"claude"
  end
end
