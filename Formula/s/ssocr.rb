class Ssocr < Formula
  desc "Seven Segment Optical Character Recognition"
  homepage "https://www.unix-ag.uni-kl.de/~auerswal/ssocr/"
  url "https://www.unix-ag.uni-kl.de/~auerswal/ssocr/ssocr-2.25.1.tar.bz2"
  sha256 "e7588bb9ec56b568362ca0b68c216b0af37b42bb3f63602ee21628aa731b84be"
  license "GPL-3.0-or-later"
  head "https://github.com/auerswal/ssocr.git", branch: "master"

  livecheck do
    url :homepage
    regex(/href=.*?ssocr[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "01914c3b549ad1eebb9877cff4c0da64025979e8e913f44a1058c173bebb7999"
  end

  depends_on "pkgconf" => :build
  depends_on "imlib2"

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    resource "homebrew-test-image" do
      url "https://www.unix-ag.uni-kl.de/~auerswal/ssocr/six_digits.png"
      sha256 "72b416cca7e98f97be56221e7d1a1129fc08d8ab15ec95884a5db6f00b2184f5"
    end

    resource("homebrew-test-image").stage testpath
    assert_equal "431432", shell_output("#{bin}/ssocr -T #{testpath}/six_digits.png").chomp
  end
end
