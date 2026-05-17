class WCalc < Formula
  desc "Very capable calculator"
  homepage "https://w-calc.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/w-calc/Wcalc/2.5/wcalc-2.5.tar.bz2"
  sha256 "0e2c17c20f935328dcdc6cb4c06250a6732f9ee78adf7a55c01133960d6d28ee"
  license "GPL-2.0-or-later"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9f2752ff0e12f367079eedb3ac34b6d67d7b74107fa7a42ce8a7ec6c6b9efe6a"
  end

  depends_on "gmp"
  depends_on "mpfr"

  def install
    # Workaround for build with newer clang
    ENV.append_to_cflags "-Wno-incompatible-function-pointer-types" if DevelopmentTools.clang_build_version >= 1500

    system "./configure", "--prefix=#{prefix}"
    system "make"
    system "make", "install"
  end

  test do
    assert_match "4", shell_output("#{bin}/wcalc 2+2")
  end
end
