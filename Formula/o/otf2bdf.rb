class Otf2bdf < Formula
  desc "OpenType to BDF font converter"
  homepage "https://github.com/jirutka/otf2bdf"
  url "https://github.com/jirutka/otf2bdf/archive/refs/tags/v3.1_p1.tar.gz"
  version "3.1_p1"
  sha256 "deb1590c249edf11dda1c7136759b59207ea0ac1c737e1c2d68dedf87c51716e"
  license "MIT"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+(?:[._-]?p\d+)?)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "793b0f9258425525e8e59ac00383a4feaba20ce309ab0a9afb1a3383fcceaca6"
  end

  depends_on "freetype"

  resource "test-font" do
    on_linux do
      url "https://raw.githubusercontent.com/paddykontschak/finder/master/fonts/LucidaGrande.ttc"
      sha256 "e188b3f32f5b2d15dbf01e9b4480fed899605e287516d7c0de6809d8e7368934"
    end
  end

  def install
    chmod 0755, "mkinstalldirs"

    # `otf2bdf.c` uses `#include <ft2build.h>`, not `<freetype2/ft2build.h>`,
    # so freetype2 must be put into the search path.
    ENV.append "CFLAGS", "-I#{Formula["freetype"].opt_include}/freetype2"

    system "./configure", "--mandir=#{man}", *std_configure_args
    system "make", "install"
  end

  test do
    if OS.mac?
      assert_match "MacRoman", shell_output("#{bin}/otf2bdf -et /System/Library/Fonts/LucidaGrande.ttc")
    else
      resource("test-font").stage do
        assert_match "MacRoman", shell_output("#{bin}/otf2bdf -et LucidaGrande.ttc")
      end
    end
  end
end
