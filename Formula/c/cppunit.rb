class Cppunit < Formula
  desc "Unit testing framework for C++"
  homepage "https://wiki.freedesktop.org/www/Software/cppunit/"
  url "https://dev-www.libreoffice.org/src/cppunit-1.15.1.tar.gz"
  sha256 "89c5c6665337f56fd2db36bc3805a5619709d51fb136e51937072f63fcc717a7"
  license "LGPL-2.1-only"

  livecheck do
    url "https://dev-www.libreoffice.org/src/"
    regex(/href=["']?cppunit[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "15123e824259b54d9c67acbe432c108ee3dcc1154e20b2bdf9fe6837bcbf1465"
  end

  def install
    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    assert_match "Usage", shell_output("#{bin}/DllPlugInTester", 2)
  end
end
