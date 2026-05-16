class Libnova < Formula
  desc "Celestial mechanics, astrometry and astrodynamics library"
  homepage "https://libnova.sourceforge.net/"
  url "https://git.code.sf.net/p/libnova/libnova.git",
      tag:      "v0.16",
      revision: "edbf65abe27ef1a2520eb9e839daaf58f15a6941"
  # libnova is LGPL but the libnovaconfig binary is GPL
  license all_of: ["LGPL-2.0-or-later", "GPL-2.0-or-later"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4c74cb8b0ff283532dca0b1c1d4e6a49fa61259492f83d5b20c5e7dce4b7c5e9"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <libnova/julian_day.h>

      int main(void)
      {
        double JD;

        JD = ln_get_julian_from_sys();
        return 0;
      }
    C

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lnova", "-o", "test"
    system "./test"
  end
end
