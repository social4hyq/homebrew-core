class GrokBuild < Formula
  desc "XAI Grok coding agent CLI — HarmonyOS aarch64 (prebuilt static binary)"
  homepage "https://github.com/xai-org/grok-build"
  url "https://storage.googleapis.com/grok-build-public-artifacts/cli/grok-0.2.106-linux-aarch64"
  version "0.2.106"
  sha256 "d12be1698d56d4543f1f1095c2c26cd3d17a64e88772629673740991c188e4ff"
  license "Apache-2.0"
  # Official release artifact, fetched directly (no npm wrapper involved).
  # The install.sh at https://x.ai/cli/install.sh resolves the download to
  # BASE_URL/grok-VERSION-PLATFORM, where BASE_URL is either the Cloudflare-
  # fronted https://x.ai/cli or, as fallback, this GCS bucket directly. We use
  # the GCS URL unconditionally: x.ai resolved to an unrelated IP range and
  # connections stalled/timed out from both this host and the OHOS container
  # (some kind of DNS interference on the x.ai name specifically), while GCS
  # answered every time. sha256 verified byte-identical to what x.ai served
  # on the one successful fetch. `version`/`sha256` must be bumped by hand for
  # new releases — livecheck below only resolves the current `stable` pointer.
  #
  # The binary is a single static aarch64 ELF (no INTERP/DYNAMIC segment —
  # `readelf -l` confirms it needs no dynamic linker at all), so unlike
  # opencode/codex it needs neither bundled musl runtime libraries nor
  # DT_RUNPATH injection. It also does not need ohos-compat-shim: that shim
  # works via LD_PRELOAD, which cannot intercept anything in a statically
  # linked binary anyway, and `--version`/`--help` run clean without it on
  # the real OHOS container — verified 2026-07-17.

  livecheck do
    url "https://storage.googleapis.com/grok-build-public-artifacts/cli/stable"
    regex(/^(\d+(?:\.\d+)+)/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/grok-build-v0.2.102-r1"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "929463671e303925dab8ea75f160be1ca3b7ce81cf77bc7157e56f51d2a4b682"
  end

  depends_on "ohos-bst-light" => :build

  def install
    src = buildpath/"grok-#{version}-linux-aarch64"
    odie "grok binary not found at #{src}" unless src.exist?

    sign = formula_opt_bin("ohos-bst-light")/"self-sign"
    system sign, src.to_s

    mkdir_p libexec/"bin"
    libexec.install src => "bin/grok"
    chmod 0755, libexec/"bin/grok"

    # Self-reference via opt_libexec (prefix-relative, stable) rather than
    # libexec (Cellar-relative) — same HOMEBREW_CELLAR-flip reasoning as the
    # other OHOS CLI formulas in this tap (see opencode.rb / codex.rb).
    (bin/"grok").write <<~SH
      #!/bin/sh
      export TMPDIR="${GROK_TMPDIR:-/data/storage/el2/base/cache}"
      exec "#{opt_libexec}/bin/grok" "$@"
    SH
    chmod 0755, bin/"grok"

    # Generate from the libexec binary: the bin/grok wrapper execs
    # opt_libexec, whose opt/ symlink only exists after install.
    generate_completions_from_executable(libexec/"bin/grok", "completions")
  end

  def caveats
    <<~EOS
      Grok Build requires authentication. Either sign in interactively:
        grok login --device-auth   # device-code flow, no local browser needed

      or use an API key (CI/headless):
        export XAI_API_KEY=xai-xxx

      Sandbox mode (Landlock, `--sandbox workspace|read-only|strict`) relies on
      Linux kernel namespaces that OHOS does not provide — leave it at the
      default `off` on this platform.

      Don't run `grok update`: this build is managed by Homebrew. Use
      `brew upgrade grok-build` instead.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/grok --version 2>&1")
  end
end
