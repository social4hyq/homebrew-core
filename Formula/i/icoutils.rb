class Icoutils < Formula
  desc "Create and extract MS Windows icons and cursors"
  homepage "https://www.nongnu.org/icoutils/"
  url "https://download.savannah.gnu.org/releases/icoutils/icoutils-0.32.3.tar.bz2"
  sha256 "17abe02d043a253b68b47e3af69c9fc755b895db68fdc8811786125df564c6e0"
  license "GPL-3.0-or-later"

  livecheck do
    url "https://download.savannah.gnu.org/releases/icoutils/"
    regex(/href=.*?icoutils[._-](\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f4ca2e6a98568b846b8995e0ce9811ca0f2d7a6f84127c1b737c86213d1ec26a"
  end

  depends_on "libpng"

  on_monterey :or_newer do
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  def install
    inreplace "common/Makefile.am", "libcommon_a_LIBADD", "libcommon_la_LIBADD"

    # Workaround for Xcode 14 ld.
    system "autoreconf", "--force", "--install", "--verbose" if OS.mac? && MacOS.version >= :monterey

    system "./configure", "--disable-rpath", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"icotool", "-l", test_fixtures("test.ico")
  end
end
