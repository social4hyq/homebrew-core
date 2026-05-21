class Libfs < Formula
  desc "X.Org: X Font Service client library"
  homepage "https://www.x.org/"
  url "https://xorg.freedesktop.org/archive/individual/lib/libFS-1.0.10.tar.gz"
  sha256 "38daddf6aaad25d93c6ff762c9629b8f10b19e8c4b70fcf117ec38c440ff9ae2"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8834fc2b3431addadd708fccd5b4427762a8e84a09ce4da784188f01aa777f82"
  end

  depends_on "pkgconf" => :build
  depends_on "xtrans" => :build
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
      #include "X11/fonts/FSlib.h"

      int main(int argc, char* argv[]) {
        FSExtData data;
        return 0;
      }
    C
    system ENV.cc, "test.c"
    assert_equal 0, $CHILD_STATUS.exitstatus
  end
end
