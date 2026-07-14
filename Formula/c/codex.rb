class Codex < Formula
  desc "OpenAI Codex CLI — HarmonyOS aarch64 (Linux musl binary + OHOS signing)"
  homepage "https://github.com/openai/codex"
  version "0.144.3"
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
  url "https://registry.npmjs.org/@openai/codex/-/codex-#{version}-linux-arm64.tgz"
  sha256 "33384d62153cad2b197eaff2204c1da3d3e0c317c856cc14aa540254b25c69df"
  license "Apache-2.0"

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/codex-v0.144.3"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2270e682824354cd412cd00232ca67dae2f7cf3c977af6e004e89f79609aea71"
  end

  livecheck do
    url "https://registry.npmjs.org/@openai/codex/latest"
    regex(/"version":\s*"(\d+(?:\.\d+)+)"/)
  end

  depends_on "ohos-bst-light"  => :build
  depends_on "close-range-shim"
  depends_on "ripgrep"

  def install
    vendor = buildpath/"vendor/aarch64-unknown-linux-musl"
    sign = Formula["ohos-bst-light"].opt_bin/"self-sign"

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
    ln_sf Formula["ripgrep"].opt_bin/"rg", libexec/"codex-path/rg"

    # bwrap/landlock sandbox (codex-resources/) is non-functional on OHOS
    # (no user namespaces / setuid) — see caveats to disable sandbox_mode.

    (bin/"codex").write <<~SH
      #!/bin/sh
      export LD_PRELOAD="#{Formula["close-range-shim"].opt_lib}/libclose_range_shim.so${LD_PRELOAD:+:$LD_PRELOAD}"
      export TMPDIR="${CODEX_TMPDIR:-/data/storage/el2/base/cache}"
      export SHELL="${SHELL:-/bin/sh}"
      exec "#{libexec}/bin/codex" "$@"
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
