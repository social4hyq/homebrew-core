class Tealdeer < Formula
  desc "Very fast implementation of tldr in Rust"
  homepage "https://tealdeer-rs.github.io/tealdeer/"
  url "https://github.com/tealdeer-rs/tealdeer/archive/refs/tags/v1.9.0.tar.gz"
  sha256 "1387a04ddba714668ff0925377a2de0d0ab14533d44dd0766d673fbbd71e3119"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/tealdeer-rs/tealdeer.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f38385341318c543eb3b6cfd573a35a691237cca435b7fececcf9086f58ed770"
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
