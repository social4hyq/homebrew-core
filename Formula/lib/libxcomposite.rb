class Libxcomposite < Formula
  desc "X.Org: Client library for the Composite extension"
  homepage "https://www.x.org/"
  url "https://www.x.org/archive/individual/lib/libXcomposite-0.4.7.tar.xz"
  sha256 "8bdf310967f484503fa51714cf97bff0723d9b673e0eecbf92b3f97c060c8ccb"
  license "MIT"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c365cf0e376faa6ede2efd8d7e02747f362c4267f015b6d6274e3f56634d39fc"
  end

  depends_on "pkgconf" => :build
  depends_on "libx11"
  depends_on "libxfixes"
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
      #include "X11/extensions/Xcomposite.h"

      int main(int argc, char* argv[]) {
        Display *d = NULL;
        int s = DefaultScreen(d);
        Window root = RootWindow(d, s);
        XCompositeReleaseOverlayWindow(d, s);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lXcomposite"
    assert_equal 0, $CHILD_STATUS.exitstatus
  end
end
