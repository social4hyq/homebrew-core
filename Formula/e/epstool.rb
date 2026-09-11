class Epstool < Formula
  desc "Edit preview images and fix bounding boxes in EPS files"
  homepage "http://www.ghostgum.com.au/software/epstool.htm"
  url "https://deb.debian.org/debian/pool/main/e/epstool/epstool_3.09.orig.tar.xz"
  sha256 "1e85249d1a44f9418b1f95a3aebd8b0784dab8e49deb6417ac9b996ca08f6011"
  license "GPL-2.0-only"
  revision 1

  livecheck do
    url :homepage
    regex(/href=.*?epstool[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a05e0ded518600cd7a1f84afcaaf5eb4c994827b655355d2d0310d36dca9e577"
  end

  depends_on "ghostscript"

  def install
    system "make", "install",
                   "EPSTOOL_ROOT=#{prefix}",
                   "EPSTOOL_MANDIR=#{man}",
                   "CC=#{ENV.cc}"
  end

  test do
    system bin/"epstool", "--add-tiff-preview", "--device", "tiffg3", test_fixtures("test.eps"), "test2.eps"
    assert_path_exists testpath/"test2.eps"
  end
end
