class Tre < Formula
  desc "Lightweight, POSIX-compliant regular expression (regex) library"
  homepage "https://github.com/laurikari/tre"
  url "https://github.com/laurikari/tre/releases/download/v0.9.0/tre-0.9.0.tar.gz"
  sha256 "f57f5698cafdfe516d11fb0b71705916fe1162f14b08cf69d7cf86923b5a2477"
  license "BSD-2-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "48cdb7cbb0ed9442384683b146bd909c214a550903d3e63c397346e399f8e597"
  end

  def install
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    assert_equal "brow", pipe_output("#{bin}/agrep -1 brew", "brow", 0)
  end
end
