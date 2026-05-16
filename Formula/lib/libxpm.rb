class Libxpm < Formula
  desc "X.Org: X Pixmap (XPM) image file format library"
  homepage "https://www.x.org/"
  url "https://www.x.org/archive/individual/lib/libXpm-3.5.19.tar.gz"
  sha256 "f241f705c607fba1a53338f7e1c12005d6da326b5cb55a11a10847781b4578c0"
  license "MIT"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f8f22d5fa70201fc6358f4885d73bbb366357716a35e3400db267eb716b962ae"
  end

  depends_on "gettext" => :build
  depends_on "pkgconf" => :build
  depends_on "libx11"

  on_macos do
    depends_on "gettext"
  end

  def install
    args = %W[
      --sysconfdir=#{etc}
      --localstatedir=#{var}
      --disable-open-zfile
      --disable-silent-rules
      --disable-stat-zfile
    ]

    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include "X11/Xlib.h"
      #include "X11/xpm.h"

      int main(int argc, char* argv[]) {
        XpmColor color;
        return 0;
      }
    C
    system ENV.cc, "test.c"
    assert_equal 0, $CHILD_STATUS.exitstatus
  end
end
