class Libxrender < Formula
  desc "X.Org: Library for the Render Extension to the X11 protocol"
  homepage "https://www.x.org/"
  url "https://www.x.org/archive/individual/lib/libXrender-0.9.12.tar.gz"
  sha256 "0fff64125819c02d1102b6236f3d7d861a07b5216d8eea336c3811d31494ecf7"
  license "MIT"
  revision 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8dfb71a79b61b329e08081c96c033935b1e5a29ac84b7f4743a6bf5b4ab78581"
  end

  depends_on "pkgconf" => :build
  depends_on "libx11"
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
      #include "X11/extensions/Xrender.h"

      int main(int argc, char* argv[]) {
        XRenderColor color;
        return 0;
      }
    C
    system ENV.cc, "test.c"
    assert_equal 0, $CHILD_STATUS.exitstatus
  end
end
