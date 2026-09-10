class Pcre < Formula
  desc "Perl compatible regular expressions library"
  homepage "https://www.pcre.org/"
  url "https://downloads.sourceforge.net/project/pcre/pcre/8.45/pcre-8.45.tar.bz2"
  mirror "https://www.mirrorservice.org/sites/ftp.exim.org/pub/pcre/pcre-8.45.tar.bz2"
  sha256 "4dae6fdcd2bb0bb6c37b5f97c33c2be954da743985369cddac3546e3218bffb8"
  license "BSD-3-Clause"
  revision 1

  # From the PCRE homepage:
  # "The older, but still widely deployed PCRE library, originally released in
  # 1997, is at version 8.45. This version of PCRE is now at end of life, and
  # is no longer being actively maintained. Version 8.45 is expected to be the
  # final release of the older PCRE library, and new projects should use PCRE2
  # instead."
  livecheck do
    skip "PCRE was declared end of life in 2021-06"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a65f6b3dde602779466080f468acd06b5ea5c9b7f10d1d33e0cf7f9b63e90b94"
  end

  uses_from_macos "bzip2"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-big_sur.diff"
    sha256 "35acd6aebc19843f1a2b3a63e880baceb0f5278ab1ace661e57a502d9d78c93c"
  end

  def install
    args = %w[
      --enable-utf8
      --enable-pcre8
      --enable-pcre16
      --enable-pcre32
      --enable-unicode-properties
      --enable-pcregrep-libz
      --enable-pcregrep-libbz2
    ]

    # JIT not currently supported for Apple Silicon
    args << "--enable-jit" if OS.mac? && !Hardware::CPU.arm?

    system "./configure", *args, *std_configure_args
    system "make"
    ENV.deparallelize
    system "make", "test"
    system "make", "install"
  end

  test do
    system bin/"pcregrep", "regular expression", prefix/"README"
  end
end
