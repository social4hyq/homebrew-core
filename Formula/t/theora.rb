class Theora < Formula
  desc "Open video compression format"
  homepage "https://www.theora.org/"
  url "https://ftp.osuosl.org/pub/xiph/releases/theora/libtheora-1.2.0.tar.gz"
  mirror "https://mirror.csclub.uwaterloo.ca/xiph/releases/theora/libtheora-1.2.0.tar.gz"
  sha256 "279327339903b544c28a92aeada7d0dcfd0397b59c2f368cc698ac56f515906e"
  license "BSD-3-Clause"
  compatibility_version 1

  livecheck do
    url "https://ftp.osuosl.org/pub/xiph/releases/theora/?C=M&O=D"
    regex(%r{href=(?:["']?|.*?/)libtheora[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d15166952ff8793074c92113bb36e8c1857b6d61543f0e7df363169bfaba11d8"
  end

  head do
    url "https://gitlab.xiph.org/xiph/theora.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  depends_on "pkgconf" => :build
  depends_on "libogg"
  depends_on "libvorbis"

  def install
    system "./autogen.sh" if build.head?

    args = %w[
      --disable-oggtest
      --disable-vorbistest
      --disable-examples
    ]
    args << "--disable-asm" if build.head?

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <theora/theora.h>

      int main()
      {
          theora_info inf;
          theora_info_init(&inf);
          theora_info_clear(&inf);
          return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-ltheora", "-o", "test"
    system "./test"
  end
end
