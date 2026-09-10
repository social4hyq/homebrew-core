class Gif2png < Formula
  desc "Convert GIFs to PNGs"
  homepage "http://www.catb.org/~esr/gif2png/"
  url "https://gitlab.com/esr/gif2png/-/archive/3.0.5/gif2png-3.0.5.tar.bz2"
  sha256 "8cc0733ad5d48329da903d1a56e01adbaa4994181f5a12ce962fd4f2c504da22"
  license "BSD-2-Clause"
  revision 1
  head "https://gitlab.com/esr/gif2png.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f772f55c5cedf41784f71036a0390c2be7b61c69e90152a354a4020433984335"
  end

  depends_on "asciidoctor" => :build
  depends_on "go" => :build

  uses_from_macos "python" # for web2png

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    cp test_fixtures("test.gif"), testpath/"test.gif"
    system bin/"gif2png", "test.gif"
    assert_path_exists testpath/"test.png"
  end
end
