class Libbs2b < Formula
  desc "Bauer stereophonic-to-binaural DSP"
  homepage "https://bs2b.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/bs2b/libbs2b/3.1.0/libbs2b-3.1.0.tar.gz"
  sha256 "6aaafd81aae3898ee40148dd1349aab348db9bfae9767d0e66e0b07ddd4b2528"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "710a36a84eae5d04d8202d7ea698f19cd9c08d9155927346ee001bce56376220"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build
  depends_on "libsndfile"

  def install
    # fix 'error: support for lzma-compressed distribution archives has been removed'
    inreplace "configure.ac", "dist-lzma", ""
    system "autoreconf", "--force", "--verbose", "--install"

    system "./configure", "--disable-static", "--enable-shared", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <bs2b/bs2b.h>

      int main()
      {
        t_bs2bdp info = bs2b_open();
        if (info == 0)
        {
          return 1;
        }
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lbs2b", "-o", "test"
    system "./test"
  end
end
