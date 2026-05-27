class Wumpus < Formula
  desc "Exact clone of the ancient BASIC Hunt the Wumpus game"
  homepage "http://www.catb.org/~esr/wumpus/"
  url "https://gitlab.com/esr/wumpus/-/archive/1.12/wumpus-1.12.tar.bz2"
  sha256 "0963a7690e0e739f757d59dc1df07083fa96d3a27d800d571a1977a6d0fa48ef"
  license "BSD-2-Clause"
  head "https://gitlab.com/esr/wumpus.git", branch: "master"

  # The homepage links to the `stable` tarball but it can take longer than the
  # ten second livecheck timeout, so we check the Git tags as a workaround.
  livecheck do
    url :head
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fc23aa226456defc851d3cf0b6006bb9f9d8d1b28a0e6d4b7ff6db23ad2dd42e"
  end

  depends_on "asciidoctor" => :build

  def install
    system "make", "all", "wumpus.6", "CFLAGS=#{ENV.cflags}"
    # Not using `make install` due to issues with Makefile
    # https://gitlab.com/esr/wumpus/-/issues/3
    bin.install "wumpus", "superhack"
    man6.install "wumpus.6"
  end

  test do
    assert_match("HUNT THE WUMPUS",
                 pipe_output(bin/"wumpus", "^C"))
  end
end
