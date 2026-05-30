class Libxres < Formula
  desc "X.Org: X-Resource extension client library"
  homepage "https://www.x.org/"
  url "https://www.x.org/archive/individual/lib/libXres-1.2.3.tar.xz"
  sha256 "d2de8f5401d6c86a8992791654547eb8def585dfdc0c08cc16e24ef6aeeb69dc"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e91661e194026aa277dee8412b97672f30815a2c495d9c40c8c029e5535f34ab"
  end

  depends_on "pkgconf" => :build
  depends_on "xorgproto" => :build
  depends_on "libx11"
  depends_on "libxext"

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
      #include "X11/extensions/XRes.h"

      int main(int argc, char* argv[]) {
        XResType client;
        return 0;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lXRes"
    assert_equal 0, $CHILD_STATUS.exitstatus
  end
end
