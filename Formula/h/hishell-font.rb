class HishellFont < Formula
  desc "Install and configure a Nerd Font (nerd-fonts.com) for hishell's terminal"
  homepage "https://github.com/social4hyq/ohos-hishell-font"
  url "https://github.com/social4hyq/ohos-hishell-font.git",
      revision: "ab256914f4ae5cb8fed99eddd8cdcdf1af993aa0"
  version "0.1.0"
  license "MIT"

  livecheck do
    skip "development tool, manually versioned"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/hishell-font-v0.1.0-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6e9ff638365a716f3cfde5f409484dd3dd3081d1952750feb5f6d4488548bce7"
  end

  # hishell (com.huawei.hmos.hishell) is Alacritty's HarmonyOS port; its terminal core
  # (libalacritty_terminal.so) resolves fonts through a bundled fontconfig instance, and has
  # no ArkTS/UI-level way to choose a font family — the toml config's [font.normal] family
  # field is parsed with a regex that only ever matches digits, never a real font name. This
  # tool downloads a font from nerd-fonts.com's GitHub releases, installs it, and writes the
  # fontconfig conf.d rule that's the only thing that actually works.
  #
  # fc-match/fc-scan (fontconfig) do the actual font lookup and self-verification; gnu-tar/xz
  # extract the downloaded .tar.xz archive. All are runtime, not build, dependencies — this
  # formula only builds a JS bundle, nothing native.
  depends_on "bun"
  depends_on "fontconfig"
  depends_on "gnu-tar"
  depends_on "xz"

  def install
    ENV["BUN_INSTALL_CACHE_DIR"] = (HOMEBREW_CACHE/"bun-install-cache").to_s
    system "bun", "install", "--frozen-lockfile"
    system "bun", "build", "--target=bun", "--outfile", "hishell-font.js", "src/cli.ts"
    libexec.install "hishell-font.js"

    # $HOMEBREW_PREFIX is resolved at *runtime* inside the script, not interpolated at build
    # time — this is a plain shell script, not a binary being RUNPATH-patched, so baking the
    # build machine's prefix in here would break portability the same way an absolute path
    # would in any other relocatable bottle. Same pattern as sshport.rb.
    #
    # fc-match/fc-scan/tar/xz are resolved via $HOMEBREW_PREFIX/opt/*/bin rather than PATH:
    # PATH order at runtime isn't guaranteed to put this formula's own dependencies first
    # (e.g. an OHOS-native tar could shadow gnu-tar), and download.ts/fontinstall.ts/doctor.ts
    # all fall back to `Bun.which` only when these env vars are unset (see their tests).
    (bin/"hishell-font").write <<~SH
      #!/bin/sh
      : "${HOMEBREW_PREFIX:?hishell-font: HOMEBREW_PREFIX not set; run 'brew shellenv' first}"
      export PATH="$HOMEBREW_PREFIX/opt/fontconfig/bin:$HOMEBREW_PREFIX/opt/gnu-tar/bin:$HOMEBREW_PREFIX/opt/xz/bin:$PATH"
      exec "$HOMEBREW_PREFIX/opt/bun/bin/bun" "$HOMEBREW_PREFIX/opt/hishell-font/libexec/hishell-font.js" "$@"
    SH
    chmod 0755, bin/"hishell-font"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/hishell-font --version 2>&1")
    # `doctor`'s only I/O is filesystem probes + `Bun.which`-style PATH lookups (no network),
    # so it's safe to run unconditionally — same rationale as sshport.rb's `doctor` test.
    # Its exit code legitimately varies by machine (1 outside hishell's own app sandbox, which
    # the CI build environment is), so only the header line is asserted, not the exit code.
    assert_match "hishell-font doctor", shell_output("#{bin}/hishell-font doctor 2>&1", 1)
  end
end
