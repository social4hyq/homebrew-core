class HishellFont < Formula
  desc "Install and configure a Nerd Font (nerd-fonts.com) for hishell's terminal"
  homepage "https://github.com/social4hyq/ohos-hishell-font"
  url "https://github.com/social4hyq/ohos-hishell-font/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "6569102dd4b56c7b657dce1a13e16cc3f56c6d42b9458d3cce1edce2e329d8b2"
  license "MIT"
  revision 1

  livecheck do
    skip "development tool, manually versioned"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/hishell-font-v0.1.0-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6e9ff638365a716f3cfde5f409484dd3dd3081d1952750feb5f6d4488548bce7"
  end

  # hishell (Alacritty OHOS port) resolves fonts via bundled fontconfig — there's no
  # UI-level font picker, the toml [font.normal] regex only matches digits. This tool
  # installs a Nerd Font and writes the fontconfig conf.d rule. fc-match/gnu-tar/xz
  # are runtime deps (this formula only builds a JS bundle).
  depends_on "bun"
  depends_on "fontconfig"
  depends_on "gnu-tar"
  depends_on "xz"

  def install
    ENV["BUN_INSTALL_CACHE_DIR"] = (HOMEBREW_CACHE/"bun-install-cache").to_s
    system "bun", "install", "--frozen-lockfile"
    system "bun", "build", "--target=bun", "--outfile", "hishell-font.js", "src/cli.ts"
    libexec.install "hishell-font.js"

    # fc-match/tar/xz prepended to PATH explicitly (OHOS-native tar could shadow gnu-tar).
    (bin/"hishell-font").write_env_script formula_opt_bin("bun")/"bun", [opt_libexec/"hishell-font.js"],
                                           PATH: "#{formula_opt_bin("fontconfig")}:" \
                                                 "#{formula_opt_bin("gnu-tar")}:#{formula_opt_bin("xz")}:$PATH"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/hishell-font --version 2>&1")
    # `doctor` is local-only (no network). Exit code varies by machine,
    # so only assert the header line.
    assert_match "hishell-font doctor", shell_output("#{bin}/hishell-font doctor 2>&1", 1)
  end
end
