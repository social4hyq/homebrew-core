require File.expand_path("../../Abstract/portable-formula", __dir__)

class PortableLibiconv < PortableFormula
  desc "Conversion library"
  homepage "https://www.gnu.org/software/libiconv/"
  url "https://ftpmirror.gnu.org/gnu/libiconv/libiconv-1.19.tar.gz"
  mirror "https://ftp.gnu.org/gnu/libiconv/libiconv-1.19.tar.gz"
  sha256 "88dd96a8c0464eca144fc791ae60cd31cd8ee78321e67397e25fc095c4a19aa6"
  license all_of: ["GPL-3.0-or-later", "LGPL-2.0-or-later"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6ca0ef5ba87de70cca0d983d795d288e9a9e62f06d699fae6116b04366fa4c0a"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "gperf" => :build

  def install
    ENV.deparallelize

    # Reported at https://savannah.gnu.org/bugs/index.php?66170
    ENV.append_to_cflags "-Wno-incompatible-function-pointer-types" if DevelopmentTools.clang_build_version >= 1500

    args = %W[
      --enable-extra-encodings
      --enable-static
      --docdir=#{doc}
      --disable-shared
    ]
    system "./configure", *args, *std_configure_args

    make_args = %W[
      CFLAGS=#{ENV.cflags}
      CC=#{ENV.cc}
      ACLOCAL=aclocal
      AUTOMAKE=automake
    ]
    system "make", "-f", "Makefile.devel", *make_args
    system "make", "install"
  end

  test do
    system bin/"iconv", "--help"
  end
end
