class Libmicrohttpd < Formula
  desc "Light HTTP/1.1 server library"
  homepage "https://www.gnu.org/software/libmicrohttpd/"
  url "https://ftpmirror.gnu.org/gnu/libmicrohttpd/libmicrohttpd-1.0.9.tar.gz"
  mirror "https://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-1.0.9.tar.gz"
  sha256 "6e9adc446b08083ec03d40317fb66ca6f2e03e4f6170aef33a6e59bb08db2012"
  license "LGPL-2.1-or-later"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e253c7bc9a05f11235b53eb862cd0cc06dd96325ed7d0ac6ea6adaf55d527374"
  end

  depends_on "pkgconf" => :build
  depends_on "gnutls"

  def install
    system "./configure", "--disable-silent-rules",
                          "--enable-https",
                          *std_configure_args
    system "make", "install"
    (pkgshare/"examples").install Dir.glob("doc/examples/*.c")
  end

  test do
    cp pkgshare/"examples/simplepost.c", testpath
    inreplace "simplepost.c",
      "return 0",
      "printf(\"daemon %p\", daemon) ; return 0"
    system ENV.cc, "-o", "foo", "simplepost.c", "-I#{include}", "-L#{lib}", "-lmicrohttpd"
    assert_match(/daemon 0x[0-9a-f]+[1-9a-f]+/, pipe_output("./foo"))
  end
end
