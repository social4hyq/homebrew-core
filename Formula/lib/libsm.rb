class Libsm < Formula
  desc "X.Org: X Session Management Library"
  homepage "https://www.x.org/"
  url "https://www.x.org/archive/individual/lib/libSM-1.2.6.tar.xz"
  sha256 "be7c0abdb15cbfd29ac62573c1c82e877f9d4047ad15321e7ea97d1e43d835be"
  license "MIT"
  revision 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1f2ff9c068cca899edca0d8a11c54e60066e2fb5e2e7f79a9ed29db81e776f23"
  end

  depends_on "pkgconf" => :build
  depends_on "xtrans" => :build
  depends_on "libice"

  def install
    args = %W[
      --sysconfdir=#{etc}
      --localstatedir=#{var}
      --disable-silent-rules
      --enable-docs=no
    ]

    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include "X11/SM/SMlib.h"

      int main(int argc, char* argv[]) {
        SmProp prop;
        return 0;
      }
    C
    system ENV.cc, "test.c"
    assert_equal 0, $CHILD_STATUS.exitstatus
  end
end
