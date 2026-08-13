class HishellFont < Formula
  desc "Install and configure a Nerd Font (nerd-fonts.com) for hishell's terminal"
  homepage "https://github.com/social4hyq/ohos-hishell-font"
  url "https://github.com/social4hyq/ohos-hishell-font.git",
      tag: "v0.1.0", revision: "ab256914f4ae5cb8fed99eddd8cdcdf1af993aa0"
  license "MIT"
  revision 1

  livecheck do
    skip "development tool, manually versioned"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/hishell-font-v0.1.0-r3"
    sha256 cellar: "/storage/Users/currentUser/.harmonybrew/Cellar", arm64_ohos: "ffe76cfc939a334125d27e13249d2540960fcaebbbc179d8969b33fc58e0d43d"
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

    bin_paths = [formula_opt_bin("fontconfig"), formula_opt_bin("gnu-tar"), formula_opt_bin("xz")].join(":") +
                ":$PATH"
    (bin/"hishell-font").write_env_script(
      formula_opt_bin("bun")/"bun",
      opt_libexec/"hishell-font.js",
      "PATH" => bin_paths,
    )
    chmod 0755, bin/"hishell-font"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/hishell-font --version 2>&1")
    # `doctor` is local-only (no network). Exit code varies by machine,
    # so only assert the header line.
    assert_match "hishell-font doctor", shell_output("#{bin}/hishell-font doctor 2>&1", 1)
  end
end
