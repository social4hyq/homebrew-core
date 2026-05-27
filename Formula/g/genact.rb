class Genact < Formula
  desc "Nonsense activity generator"
  homepage "https://github.com/svenstaro/genact"
  url "https://github.com/svenstaro/genact/archive/refs/tags/v1.5.1.tar.gz"
  sha256 "07d62d0c7a41e83bf4ab8b76a1c0754556697faf5aa023b4e34906ff52323a7d"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "147802e7418111cb0029f30c481986366bfc4b972dbd967743e29675795b0ccd"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    generate_completions_from_executable(bin/"genact", "--print-completions")
  end

  test do
    assert_match "Available modules:", shell_output("#{bin}/genact --list-modules")
  end
end
