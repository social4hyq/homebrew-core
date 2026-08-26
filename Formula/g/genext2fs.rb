class Genext2fs < Formula
  desc "Generates an ext2 filesystem as a normal (non-root) user"
  homepage "https://genext2fs.sourceforge.net/"
  url "https://github.com/bestouff/genext2fs/archive/refs/tags/v1.6.3.tar.gz"
  sha256 "e3503a5bae3fd4b5b2c2d4f49b5b7f8d08e7accb20ab28c0f9647389b2c8a079"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0106aa4c6423f53b8c9f641ff87361674352c0ef973ac1c03907e0927e8de8cf"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  def install
    system "./autogen.sh"
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    rootpath = testpath/"img"
    (rootpath/"foo.txt").write "hello world"
    system bin/"genext2fs", "--root", rootpath,
                               "--block-size", "4096",
                               "--size-in-blocks", "100",
                               "#{testpath}/test.img"
  end
end
