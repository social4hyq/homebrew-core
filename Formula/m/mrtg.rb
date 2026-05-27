class Mrtg < Formula
  desc "Multi router traffic grapher"
  homepage "https://oss.oetiker.ch/mrtg/"
  url "https://oss.oetiker.ch/mrtg/pub/mrtg-2.17.10.tar.gz"
  sha256 "c7f11cb5e217a500d87ee3b5d26c58a8652edbc0d3291688bb792b010fae43ac"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://oss.oetiker.ch/mrtg/pub/"
    regex(/href=.*?mrtg[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "52c3153b41177233c9b8814a4dfdf4215d9ad16bc97c31218cb1806dccdefea8"
  end

  depends_on "gd"
  depends_on "libpng"

  def install
    # Exclude unrecognized options
    args = std_configure_args.reject { |s| s["--disable-debug"] || s["--disable-dependency-tracking"] }

    system "./configure", *args
    system "make", "install"
  end

  test do
    system bin/"cfgmaker", "--nointerfaces", "localhost"
  end
end
