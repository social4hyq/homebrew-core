class Speexdsp < Formula
  desc "Speex audio processing library"
  homepage "https://speex.org/"
  url "https://ftp.osuosl.org/pub/xiph/releases/speex/speexdsp-1.2.1.tar.gz"
  mirror "https://mirror.csclub.uwaterloo.ca/xiph/releases/speex/speexdsp-1.2.1.tar.gz"
  sha256 "8c777343e4a6399569c72abc38a95b24db56882c83dbdb6c6424a5f4aeb54d3d"
  license "BSD-3-Clause"

  livecheck do
    url "https://ftp.osuosl.org/pub/xiph/releases/speex/?C=M&O=D"
    regex(%r{href=(?:["']?|.*?/)speexdsp[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6eee7bb9eb4d94dddc123f3cbadb8b864a1d239b9083d00600b758b26d6213bf"
  end

  head do
    url "https://gitlab.xiph.org/xiph/speexdsp.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkgconf" => :build

  def install
    system "./autogen.sh" if build.head?
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <speex/speex_resampler.h>
      #include <stdlib.h>

      int main()
      {
          SpeexResamplerState *st = speex_resampler_init(1, 8000, 12000, 10, NULL);
          speex_resampler_set_rate(st, 96000, 44100);
          speex_resampler_skip_zeros(st);
          speex_resampler_destroy(st);

          return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lspeexdsp", "-o", "test"
    system "./test"
  end
end
