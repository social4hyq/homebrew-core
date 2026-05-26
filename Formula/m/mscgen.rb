class Mscgen < Formula
  desc "Parses Message Sequence Chart descriptions and produces images"
  homepage "https://www.mcternan.me.uk/mscgen/"
  url "https://www.mcternan.me.uk/mscgen/software/mscgen-src-0.20.tar.gz"
  sha256 "3c3481ae0599e1c2d30b7ed54ab45249127533ab2f20e768a0ae58d8551ddc23"
  license "GPL-2.0-or-later"
  revision 4

  livecheck do
    url :homepage
    regex(/href=.*?mscgen-src[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dcbacd23ebec25fa3def2c29fb0e2408489ca246732181b74c9bbe109e72149a"
  end

  depends_on "pkgconf" => :build
  depends_on "freetype"
  depends_on "gd"

  def install
    system "./configure", "--with-freetype", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.msc").write <<~EOS
      msc {
        width = "800";
        a, b, "c";
        a->b;
        a<-c [label="return"];
      }
    EOS

    expected_svg = <<~EOS
      <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
       "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
      <svg version="1.1"
       width="798px" height="78px"
       viewBox="0 0 798 78"
       xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges"
       stroke-width="1" text-rendering="geometricPrecision">
      <polygon fill="white" points="128,7 136,7 136,16 128,16"/>
      <text x="133" y="16" textLength="7" font-family="Helvetica" font-size="12" fill="black" text-anchor="middle">

      a
      </text>
      <polygon fill="white" points="394,7 402,7 402,16 394,16"/>
      <text x="399" y="16" textLength="7" font-family="Helvetica" font-size="12" fill="black" text-anchor="middle">

      b
      </text>
      <polygon fill="white" points="660,7 668,7 668,16 660,16"/>
      <text x="665" y="16" textLength="6" font-family="Helvetica" font-size="12" fill="black" text-anchor="middle">

      c
      </text>
      <line x1="133" y1="22" x2="133" y2="50" stroke="black"/>
      <line x1="399" y1="22" x2="399" y2="50" stroke="black"/>
      <line x1="665" y1="22" x2="665" y2="50" stroke="black"/>
      <line x1="133" y1="33" x2="399" y2="33" stroke="black"/>
      <line x1="399" y1="33" x2="389" y2="39" stroke="black"/>
      <line x1="133" y1="50" x2="133" y2="78" stroke="black"/>
      <line x1="399" y1="50" x2="399" y2="78" stroke="black"/>
      <line x1="665" y1="50" x2="665" y2="78" stroke="black"/>
      <line x1="665" y1="61" x2="133" y2="61" stroke="black"/>
      <line x1="133" y1="61" x2="143" y2="67" stroke="black"/>
      <polygon fill="white" points="382,51 415,51 415,60 382,60"/>
      <text x="383" y="60" textLength="31" font-family="Helvetica" font-size="12" fill="black">
      return
      </text>
      <line x1="133" y1="72" x2="133" y2="78" stroke="black"/>
      <line x1="399" y1="72" x2="399" y2="78" stroke="black"/>
      <line x1="665" y1="72" x2="665" y2="78" stroke="black"/>
      </svg>
    EOS

    system bin/"mscgen", "-Tsvg", "-o", testpath/"test.svg", testpath/"test.msc"
    assert_equal expected_svg, (testpath/"test.svg").read
  end
end
