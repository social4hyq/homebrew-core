class Circumflex < Formula
  desc "Hacker News in your terminal"
  homepage "https://github.com/bensadeh/circumflex"
  url "https://github.com/bensadeh/circumflex/archive/refs/tags/5.0.tar.gz"
  sha256 "04f23071b02580b474593b6f3509d9734761dfda23d978eca2e2c9f460a2e1e4"
  license "MIT"
  head "https://github.com/bensadeh/circumflex.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1c5172fcf6aedec52524d879c68f6d19ae15c2fde0734f5d0293f668301368bd"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(output: bin/"clx"), "./cmd/clx"
    man1.install "share/man/clx.1"
    bash_completion.install "share/completions/clx.bash" => "clx"
    zsh_completion.install  "share/completions/_clx"     => "_clx"
    fish_completion.install "share/completions/clx.fish"
  end

  test do
    ENV["XDG_CONFIG_HOME"] = testpath/".config"
    config_home = testpath/".config"

    assert_match "Item added to favorites", shell_output("#{bin}/clx add 1")
    assert_path_exists config_home/"circumflex/favorites.toml"
  end
end
