class Hexd < Formula
  desc "Colourful, human-friendly hexdump tool"
  homepage "https://github.com/FireyFly/hexd"
  url "https://github.com/FireyFly/hexd/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "de0db7205c8eb0f170263aca27f5d48963855345bc79ba4842edd21a938d0326"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cf2706df5e517361d171173e0811f34471ffc014502c2e387858aaee8de9dbce"
  end

  def install
    # BSD install does not understand the GNU "-D" flag.
    inreplace "Makefile", "install -D", "install"

    bin.mkdir
    man1.mkpath
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    assert_match(/0000\s+48/, pipe_output("#{bin}/hexd -p", "H"))
  end
end
