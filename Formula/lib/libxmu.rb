class Libxmu < Formula
  desc "X.Org: X miscellaneous utility routines library"
  homepage "https://www.x.org/"
  url "https://www.x.org/archive/individual/lib/libXmu-1.3.1.tar.xz"
  sha256 "81a99e94c4501e81c427cbaa4a11748b584933e94b7a156830c3621256857bc4"
  license "MIT"
  revision 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0088cb378c58c8e06554cf8c72f02994c4fdee9a08d6741cb826775b464a7a91"
  end

  depends_on "pkgconf" => :build
  depends_on "libx11"
  depends_on "libxext"
  depends_on "libxt"

  def install
    args = %W[
      --sysconfdir=#{etc}
      --localstatedir=#{var}
      --disable-silent-rules
      --enable-docs=no
    ]

    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include "X11/Xlib.h"
      #include "X11/Xmu/Xmu.h"

      int main(int argc, char* argv[]) {
        XmuArea area;
        return 0;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lXmu"
    assert_equal 0, $CHILD_STATUS.exitstatus
  end
end
