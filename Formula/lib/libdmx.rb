class Libdmx < Formula
  desc "X.Org: X Window System DMX (Distributed Multihead X) extension library"
  homepage "https://www.x.org/"
  url "https://www.x.org/archive/individual/lib/libdmx-1.1.5.tar.xz"
  sha256 "35a4e26a8b0b2b4fe36441dca463645c3fa52d282ac3520501a38ea942cbf74f"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9b41bb17fadbc4d56e070b79783991aed25c8b3b2ba9833b852a43f79e120e44"
  end

  depends_on "pkgconf" => :build
  depends_on "libx11"
  depends_on "libxext"
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
      #include "X11/extensions/dmxext.h"

      int main(int argc, char* argv[]) {
        DMXScreenAttributes attributes;
        return 0;
      }
    C
    system ENV.cc, "test.c"
    assert_equal 0, $CHILD_STATUS.exitstatus
  end
end
