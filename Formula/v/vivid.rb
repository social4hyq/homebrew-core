class Vivid < Formula
  desc "Generator for LS_COLORS with support for multiple color themes"
  homepage "https://github.com/sharkdp/vivid"
  url "https://github.com/sharkdp/vivid/archive/refs/tags/v0.11.1.tar.gz"
  sha256 "a43ccfbc6554055181a08f2740664f9280fa2d0e57c4641850c60dd0e5323720"
  license any_of: ["MIT", "Apache-2.0"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7720dde2c49b4ee7248e6b3c0c0c96d63ea18508bfbedad2896a8a45c7cd9b40"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_includes shell_output("#{bin}/vivid preview molokai"), "archives.images: \e[4;38;2;249;38;114m*.bin\e[0m\n"
  end
end
