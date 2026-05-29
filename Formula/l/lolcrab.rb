class Lolcrab < Formula
  desc "Make your console colorful, with OpenSimplex noise"
  homepage "https://github.com/mazznoer/lolcrab"
  url "https://github.com/mazznoer/lolcrab/archive/refs/tags/v0.4.1.tar.gz"
  sha256 "b318f430e95a64dac1d92bb2a1aee2c2c0010ba74dbc5b26dc3d3dd82673dd37"
  license "MIT"
  head "https://github.com/mazznoer/lolcrab.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "27af9ef765ab278287fce65c5c877a8d42bbd49eba1b5655625e7d836b2b001e"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match "\e[38;", pipe_output(bin/"lolcrab", "lorem ipsum dolor sit amet")
    assert_match "\e[48;", pipe_output("#{bin}/lolcrab -i", "lorem ipsum dolor sit amet")
  end
end
