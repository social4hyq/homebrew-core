class Clac < Formula
  desc "Command-line, stack-based calculator with postfix notation"
  homepage "https://github.com/soveran/clac"
  url "https://github.com/soveran/clac/archive/refs/tags/0.3.5.tar.gz"
  sha256 "ae0a989ba3efc5dbe8480aed5fe39e79e274ea51271bfa7a0193d73cca0b9711"
  license "BSD-2-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f87a5b0cdf5c9da2ce01f62c1a7f334a0dac4e525dfd768406dbcb56b06e0103"
  end

  def install
    system "make", "PREFIX=#{prefix}", "install"
  end

  test do
    assert_equal "7", shell_output("#{bin}/clac '3 4 +'").strip
  end
end
