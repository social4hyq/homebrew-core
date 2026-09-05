class Pcre2 < Formula
  desc "Perl compatible regular expressions library with a new API"
  homepage "https://www.pcre.org/"
  url "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.48/pcre2-10.48.tar.bz2"
  sha256 "b6c68fdf6f3ac31388b50aa89ff0fc49c00c987c16e7b5146491d12003f2c8ed"
  license "BSD-3-Clause"
  compatibility_version 1

  livecheck do
    url :stable
    regex(/^pcre2[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2dd9742c74fb15077c6312384ae07d6bab8034a615472ee729534cd0003e4c44"
  end

  head do
    url "https://github.com/PCRE2Project/pcre2.git", branch: "main"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  uses_from_macos "bzip2"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    args = %W[
      --disable-dependency-tracking
      --prefix=#{prefix}
      --enable-pcre2-16
      --enable-pcre2-32
      --enable-pcre2grep-libz
      --enable-pcre2grep-libbz2
      --enable-jit
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
