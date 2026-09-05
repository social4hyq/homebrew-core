require File.expand_path("../../Abstract/portable-formula", __dir__)

class PortablePcre2 < PortableFormula
  desc "Perl compatible regular expressions library with a new API"
  homepage "https://www.pcre.org/"
  url "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.48/pcre2-10.48.tar.bz2"
  sha256 "b6c68fdf6f3ac31388b50aa89ff0fc49c00c987c16e7b5146491d12003f2c8ed"
  license "BSD-3-Clause"

  livecheck do
    url :stable
    regex(/^pcre2[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c8b2c21252ddb1ca96d10c69b38e9e2715f79a3a40c192a679bd4f855667fcb8"
  end

  head do
    url "https://github.com/PCRE2Project/pcre2.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  def install
    args = %W[
      --disable-dependency-tracking
      --prefix=#{prefix}
      --enable-pcre2-16
      --enable-pcre2-32
      --disable-shared
    ]

    args << "--enable-pcre2test-libedit" if OS.mac?

    system "./autogen.sh" if build.head?

    system "./configure", *args
    system "make"
    system "make", "install"
  end

  test do
    system bin/"pcre2grep", "regular expression", prefix/"README"
  end
end
