class Pngnq < Formula
  desc "Tool for optimizing PNG images"
  homepage "https://pngnq.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/pngnq/pngnq/1.1/pngnq-1.1.tar.gz"
  sha256 "c147fe0a94b32d323ef60be9fdcc9b683d1a82cd7513786229ef294310b5b6e2"
  license "BSD-3-Clause"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "734df3441d4dbd37e8efd106ff5e81b17ce2bf4c410cec5db8fa372353b33136"
  end

  depends_on "pkgconf" => :build
  depends_on "libpng"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    # Starting from libpng 1.5, the zlib.h header file
    # is no longer included internally by libpng.
    # See: https://sourceforge.net/p/pngnq/bugs/13/
    # See: https://sourceforge.net/p/pngnq/bugs/14/
    #
    # strncmp(3) is declared in <string.h>.
    # See: https://sourceforge.net/p/pngnq/patches/6/
    inreplace "src/rwpng.c",
              "#include <stdlib.h>\n",
              "#include <stdlib.h>\n#include <string.h>\n#include <zlib.h>\n"

    # The Makefile passes libpng link flags too early in the
    # command invocation, resulting in undefined references to
    # libpng symbols due to incorrect link order.
    # See: https://sourceforge.net/p/pngnq/bugs/17/
    inreplace "src/Makefile.in",
              "AM_LDFLAGS = `libpng-config --ldflags` -lz\n",
              "LDADD = `libpng-config --ldflags` -lz\n"

    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    cp test_fixtures("test.png"), "test.png"
    system bin/"pngnq", "-v", "test.png"
    assert_path_exists testpath/"test-nq8.png"
  end
end
