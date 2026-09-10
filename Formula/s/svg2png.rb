class Svg2png < Formula
  desc "SVG to PNG converter"
  homepage "https://cairographics.org/"
  url "https://cairographics.org/snapshots/svg2png-0.1.3.tar.gz"
  sha256 "e658fde141eb7ce981ad63d319339be5fa6d15e495d1315ee310079cbacae52b"
  license "LGPL-2.1-only"
  revision 3

  livecheck do
    url "https://cairographics.org/snapshots/"
    regex(/href=.*?svg2png[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c59acd98eba9548fe2c2cfb8f460984bb3e7b924e5616a53232294aaee329967"
  end

  depends_on "pkgconf" => :build
  depends_on "cairo"
  depends_on "jpeg-turbo"
  depends_on "libpng"
  depends_on "libsvg"
  depends_on "libsvg-cairo"

  conflicts_with "mapnik", because: "both install `svg2png` binaries"

  def install
    # svg2png.c:53:9: note: include the header <string.h> or explicitly provide a declaration for 'strcmp'
    inreplace("src/svg2png.c",
              "#include <stdlib.h>\n",
              "#include <stdlib.h>\n#include <string.h>\n")

    # Temporary Homebrew-specific work around for linker flag ordering problem in Ubuntu 16.04.
    # Remove after migration to 18.04.
    unless OS.mac?
      inreplace "src/Makefile.in", "$(LINK) $(svg2png_LDFLAGS) $(svg2png_OBJECTS)",
                                   "$(LINK) $(svg2png_OBJECTS) $(svg2png_LDFLAGS)"
    end

    system "./configure", "--mandir=#{man}", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"svg2png", test_fixtures("test.svg"), "test.png"
    assert_path_exists testpath/"test.png"
  end
end
