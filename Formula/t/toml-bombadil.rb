class TomlBombadil < Formula
  desc "Dotfile manager with templating"
  homepage "https://github.com/oknozor/toml-bombadil"
  url "https://github.com/oknozor/toml-bombadil/archive/refs/tags/4.2.0.tar.gz"
  sha256 "b911678642a1229908dfeabbdd7f799354346c0e37f3ac999277655e01b6f229"
  license "MIT"
  head "https://github.com/oknozor/toml-bombadil.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "518a26f8f76fcf355d80de4252a2983866650fd8339b77338430ae546eeb5c1d"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "openssl@3"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"bombadil", "generate-completions")
  end

  test do
    config_dir = if OS.mac?
      testpath/"Library/Application Support"
    else
      testpath/".config"
    end

    (config_dir/"bombadil.toml").write <<~TOML
      dotfiles_dir = "dotfiles"
    TOML

    (testpath/"dotfiles").mkpath

    output = shell_output("#{bin}/bombadil get vars")

    assert_match(/"arch":\s*".+"/, output)
    assert_match(/"os":\s*".+"/, output)
  end
end
