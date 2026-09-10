class Libxrandr < Formula
  desc "X.Org: X Resize, Rotate and Reflection extension library"
  homepage "https://www.x.org/"
  url "https://www.x.org/archive/individual/lib/libXrandr-1.5.5.tar.xz"
  sha256 "72b922c2e765434e9e9f0960148070bd4504b288263e2868a4ccce1b7cf2767a"
  license "MIT"
  revision 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0946a3dc2238cf76259860a63f60c4015d556e20f920b94cc5556bc35e8b9b39"
  end

  depends_on "pkgconf" => :build
  depends_on "libx11"
  depends_on "libxext"
  depends_on "libxrender"
  depends_on "xorgproto"

  def install
    args = %W[
      --sysconfdir=#{etc}
      --localstatedir=#{var}
      --disable-silent-rules
    ]

    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include "X11/Xlib.h"
      #include "X11/extensions/Xrandr.h"

      int main(int argc, char* argv[]) {
        XRRScreenSize size;
        return 0;
      }
    C
    system ENV.cc, "test.c"
    assert_equal 0, $CHILD_STATUS.exitstatus
  end
end
