class Tlrc < Formula
  desc "Official tldr client written in Rust"
  homepage "https://tldr.sh/tlrc/"
  url "https://github.com/tldr-pages/tlrc/archive/refs/tags/v1.13.1.tar.gz"
  sha256 "4b85b85c0299ae2ae6b78d2d52b2e597e1441da24b579034780663e33ccc85fc"
  license "MIT"
  head "https://github.com/tldr-pages/tlrc.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9ce60a833455c7d2a3ec66b1009f878d94b4ca2c4ae5d5df7d97074a389dc7a9"
  end

  depends_on "rust" => :build

  conflicts_with "tealdeer", because: "both install `tldr` binaries"
  conflicts_with "tldr", because: "both install `tldr` binaries"

  def install
    system "cargo", "install", *std_cargo_args

    man1.install "tldr.1"

    bash_completion.install "completions/tldr.bash" => "tldr"
    zsh_completion.install "completions/_tldr"
    fish_completion.install "completions/tldr.fish"
  end

  test do
    assert_match "brew", shell_output("#{bin}/tldr brew")
  end
end
