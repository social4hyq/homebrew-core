class Libxdamage < Formula
  desc "X.Org: X Damage Extension library"
  homepage "https://www.x.org/"
  url "https://www.x.org/archive/individual/lib/libXdamage-1.1.7.tar.xz"
  sha256 "127067f521d3ee467b97bcb145aeba1078e2454d448e8748eb984d5b397bde24"
  license "MIT"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "07f2718e889a92e55c63e2106baddec998230c8ce51b55dd1ff064ad35b9cbd0"
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
      #include "X11/extensions/Xdamage.h"

      int main(int argc, char* argv[]) {
        XDamageNotifyEvent event;
        return 0;
      }
    C
    system ENV.cc, "test.c"
    assert_equal 0, $CHILD_STATUS.exitstatus
  end
end
