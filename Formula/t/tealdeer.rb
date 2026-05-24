class Tealdeer < Formula
  desc "Very fast implementation of tldr in Rust"
  homepage "https://tealdeer-rs.github.io/tealdeer/"
  url "https://github.com/tealdeer-rs/tealdeer/archive/refs/tags/v1.8.1.tar.gz"
  sha256 "8b9ea7ef8dd594d6fb8b452733b0c883a68153cec266b23564ce185bdf22fcfa"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/tealdeer-rs/tealdeer.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "163fa17a77547501333066646f1905e757ef6cb2e6f2d0e40192bff85cc35cce"
  end

  depends_on "rust" => :build

  conflicts_with "tlrc", because: "both install `tldr` binaries"
  conflicts_with "tldr", because: "both install `tldr` binaries"

  def install
    system "cargo", "install", *std_cargo_args
    bash_completion.install "completion/bash_tealdeer" => "tldr"
    zsh_completion.install "completion/zsh_tealdeer" => "_tldr"
    fish_completion.install "completion/fish_tealdeer" => "tldr.fish"
  end

  test do
    assert_match "brew", shell_output("#{bin}/tldr -u && #{bin}/tldr brew")
  end
end
