class Prettyping < Formula
  desc "Wrapper to colorize and simplify ping's output"
  homepage "https://denilsonsa.github.io/prettyping/"
  url "https://github.com/denilsonsa/prettyping/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "e8484492e3c704b2460a00b0e417a07ad7112b5f4ad9a211931ee031fe64b4b6"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "465280c078214f9b1bc9c9edc396a1bd99d608fa8e0c0b6ff7674af48b769c8e"
  end

  def install
    bin.install "prettyping"
  end

  test do
    system bin/"prettyping", "-c", "3", "127.0.0.1"
  end
end
