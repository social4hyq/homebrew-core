class Libxtst < Formula
  desc "X.Org: Client API for the XTEST & RECORD extensions"
  homepage "https://www.x.org/"
  url "https://www.x.org/archive/individual/lib/libXtst-1.2.5.tar.gz"
  sha256 "244ba6e1c5ffa44f1ba251affdfa984d55d99c94bb925a342657e5e7aaf6d39c"
  license "MIT"
  revision 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "55186145d6a646950d1f1295e201faf8996829ffc5c35ccbb5d2125aa9816350"
  end

  depends_on "pkgconf" => :build
  depends_on "util-macros" => :build

  depends_on "libx11"
  depends_on "libxext"
  depends_on "libxi"
  depends_on "xorgproto"

  def install
    args = %W[
      --sysconfdir=#{etc}
      --localstatedir=#{var}
      --disable-silent-rules
      --enable-specs=no
    ]

    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include "X11/Xlib.h"
      #include "X11/extensions/record.h"

      int main(int argc, char* argv[]) {
        XRecordRange8 *range;
        return 0;
      }
    C
    system ENV.cc, "test.c"
    assert_equal 0, $CHILD_STATUS.exitstatus
  end
end
