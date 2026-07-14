class Codex < Formula
  desc "OpenAI Codex CLI — HarmonyOS aarch64 (Linux musl binary + OHOS signing)"
  homepage "https://github.com/openai/codex"
  url "https://registry.npmjs.org/@openai/codex/-/codex-0.144.3-linux-arm64.tgz"
  version "0.144.3"
  sha256 "33384d62153cad2b197eaff2204c1da3d3e0c317c856cc14aa540254b25c69df"
  license "Apache-2.0"
  revision 1
  # Codex ships a native Rust binary per platform. We fetch the linux-arm64
  # platform package directly — the @openai/codex JS wrapper throws
  # "Unsupported platform: openharmony" on OHOS. The aarch64-unknown-linux-musl
  # static binary is OHOS-compatible after self-signing.
  #
  # binary-sign-tool (Harmonybrew's automatic post-install ELF signing pass,
  # HOMEBREW_OHOS_BOTTLE_BINARY_SIGN) reliably segfaults this specific binary
  # even signing it fresh with no prior self-sign — verified empirically on
  # 2026-07-14, not just a double-signing artifact. self-sign is required;
  # build this formula with `HOMEBREW_OHOS_BOTTLE_BINARY_SIGN=` unset (or
  # `env -u HOMEBREW_OHOS_BOTTLE_BINARY_SIGN`) so the automatic pass doesn't
  # re-sign and re-break it after install() below.

  livecheck do
    url "https://registry.npmjs.org/@openai/codex/latest"
    regex(/"version":\s*"(\d+(?:\.\d+)+)"/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/codex-v0.144.3-r1b"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "01cd9dacf2bb89b1a53fc8ce92b79753bb9cfc6f1a1b3c00f8e054ed01f730da"
  end

  depends_on "ohos-bst-light" => :build
  depends_on "close-range-shim"
  depends_on "ripgrep"

  def install
    vendor = buildpath/"vendor/aarch64-unknown-linux-musl"
    sign = formula_opt_bin("ohos-bst-light")/"self-sign"

    # Self-sign the static musl binaries (self-sign preserves ELF structure,
    # unlike binary-sign-tool which corrupts this binary — see comment above).
    system sign, (vendor/"bin/codex").to_s
    system sign, (vendor/"bin/codex-code-mode-host").to_s

    # Codex resolves its resource dirs relative to its own executable
    # (package = dirname(dirname(exe)): bin/, codex-path/, codex-resources/),
    # so preserve that layout under libexec.
    (libexec/"bin").install vendor/"bin/codex"
    (libexec/"bin").install vendor/"bin/codex-code-mode-host"
    libexec.install vendor/"codex-package.json"

    # The bundled ripgrep is glibc-linked (/lib/ld-linux-aarch64.so.1) and
    # cannot run on OHOS. Replace it with the musl-native ripgrep from the tap.
    mkdir_p libexec/"codex-path"
    ln_sf formula_opt_bin("ripgrep")/"rg", libexec/"codex-path/rg"

    # bwrap/landlock sandbox (codex-resources/) is non-functional on OHOS
    # (no user namespaces / setuid) — see caveats to disable sandbox_mode.

    # Self-reference via opt_libexec (prefix-relative, stable) rather than
    # libexec (Cellar-relative). HOMEBREW_CELLAR flips between
    # HOMEBREW_PREFIX/Cellar and HOMEBREW_REPOSITORY/Cellar depending on
    # which happens to exist at brew startup (see brew.sh) — a bottle baked
    # with the Cellar-absolute path breaks if poured on a machine where that
    # resolved differently than the machine it was built on. opt/<name> is
    # always HOMEBREW_PREFIX-relative and Homebrew re-links it correctly on
    # every install, so it's stable across that flip. Verified 2026-07-14.
    (bin/"codex").write <<~SH
      #!/bin/sh
      export LD_PRELOAD="#{formula_opt_lib("close-range-shim")}/libclose_range_shim.so${LD_PRELOAD:+:$LD_PRELOAD}"
      export TMPDIR="${CODEX_TMPDIR:-/data/storage/el2/base/cache}"
      export SHELL="${SHELL:-/bin/sh}"
      exec "#{opt_libexec}/bin/codex" "$@"
    SH
    chmod 0755, bin/"codex"
  end

  def caveats
    <<~EOS
      Codex requires credentials. Run `codex login`, or set:
        export OPENAI_API_KEY=sk-xxx

      OHOS does not support the bwrap/landlock sandbox Codex uses on Linux.
      Disable it in ~/.codex/config.toml:
        sandbox_mode = "danger-full-access"
      or pass `-s danger-full-access` (or `--dangerously-bypass-approvals-and-sandbox`)
      on each invocation.

      For OpenAI-compatible APIs (e.g. DeepSeek), configure ~/.codex/config.toml:
        model_provider = "openai"
        model = "deepseek-chat"
        [model_providers.openai]
        base_url = "https://api.deepseek.com/v1"
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/codex --version 2>&1")
  end
end
