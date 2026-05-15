class Bdftopcf < Formula
  desc "Convert X font from Bitmap Distribution Format to Portable Compiled Format"
  homepage "https://gitlab.freedesktop.org/xorg/util/bdftopcf"
  url "https://www.x.org/releases/individual/util/bdftopcf-1.1.2.tar.xz"
  sha256 "bc60be5904330faaa3ddd2aed7874bee2f29e4387c245d6787552f067eb0523a"
  license "MIT-open-group"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "071b3838913edf24f6dcf8a75e634c1af7bf05e88f1af1815937da662e3d2433"
  end

  depends_on "pkgconf" => :build
  depends_on "xorgproto" => :build

  def install
    system "./configure", *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.bdf").write <<~EOS
      STARTFONT 2.1
      FONT -gnu-unifont-medium-r-normal--16-160-75-75-c-80-iso10646-1
      SIZE 16 75 75
      FONTBOUNDINGBOX 16 16 0 -2
      STARTPROPERTIES 2
      FONT_ASCENT 14
      FONT_DESCENT 2
      ENDPROPERTIES
      CHARS 1
      STARTCHAR U+0041
      ENCODING 65
      SWIDTH 500 0
      DWIDTH 8 0
      BBX 8 16 0 -2
      BITMAP
      00
      00
      00
      00
      18
      24
      24
      42
      42
      7E
      42
      42
      42
      42
      00
      00
      ENDCHAR
      ENDFONT
    EOS

    system bin/"bdftopcf", "./test.bdf", "-o", "test.pcf"
    assert_path_exists testpath/"test.pcf"
  end
end
