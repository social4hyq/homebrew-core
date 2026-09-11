class Libice < Formula
  desc "X.Org: Inter-Client Exchange Library"
  homepage "https://www.x.org/"
  url "https://www.x.org/archive/individual/lib/libICE-1.1.2.tar.xz"
  sha256 "974e4ed414225eb3c716985df9709f4da8d22a67a2890066bc6dfc89ad298625"
  license "MIT"
  revision 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6b0c5bf8dd9bbb60a817415b9c82fed70a3a9d752970c18e5acece8221e1e870"
  end

  depends_on "pkgconf" => :build
  depends_on "xtrans" => :build
  depends_on "libx11"=> :test
  depends_on "xorgproto"

  def install
    args = %W[
      --sysconfdir=#{etc}
      --localstatedir=#{var}
      --disable-silent-rules
      --enable-docs=no
      --enable-specs=no
    ]

    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include "X11/Xlib.h"
      #include "X11/ICE/ICEutil.h"

      int main(int argc, char* argv[]) {
        IceAuthFileEntry entry;
        return 0;
      }
    C
    system ENV.cc, "test.c"
    assert_equal 0, $CHILD_STATUS.exitstatus
  end
end
