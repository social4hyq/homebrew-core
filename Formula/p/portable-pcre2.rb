require File.expand_path("../../Abstract/portable-formula", __dir__)

class PortablePcre2 < PortableFormula
  desc "Perl compatible regular expressions library with a new API"
  homepage "https://www.pcre.org/"
  url "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.47/pcre2-10.47.tar.bz2"
  sha256 "47fe8c99461250d42f89e6e8fdaeba9da057855d06eb7fc08d9ca03fd08d7bc7"
  license "BSD-3-Clause"

  livecheck do
    url :stable
    regex(/^pcre2[._-]v?(\d+(?:\.\d+)+)$/i)
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
