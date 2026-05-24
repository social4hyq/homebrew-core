class Squiid < Formula
  desc "Do advanced algebraic and RPN calculations"
  homepage "https://imaginaryinfinity.net/projects/squiid/"
  url "https://gitlab.com/ImaginaryInfinity/squiid-calculator/squiid/-/archive/1.3.0/squiid-1.3.0.tar.gz"
  sha256 "bcf83dcc8bb1374866ee4fb8b31b96203476bb8cdde80cb0d24edfdbebd11469"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "62532f99269914c475bd387c3b5e8d6802d9ab3c7e1668297835715d457ee5cb"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    # squiid is a TUI app
    assert_match version.to_s, shell_output("#{bin}/squiid --version")
  end
end
