class Elio < Formula
  desc "Batteries-included terminal file manager with rich previews"
  homepage "https://github.com/elio-fm/elio"
  url "https://github.com/elio-fm/elio/archive/refs/tags/v1.11.2.tar.gz"
  sha256 "a0b30f139febc462ebc2ae20b641e358db4a8935c5262a30241fa12d822ded25"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "08082ffae5a142881a7214a88acedac620832779c3808a6298255ad3861efe2b"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    missing = testpath/"missing-directory"
    output = shell_output("#{bin}/elio #{missing} 2>&1", 1)
    assert_match "no such file or directory", output
  end
end
