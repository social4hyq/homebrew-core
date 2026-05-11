class Optipng < Formula
  desc "PNG file optimizer"
  homepage "https://optipng.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/optipng/OptiPNG/optipng-7.9.1/optipng-7.9.1.tar.gz"
  sha256 "c2579be58c2c66dae9d63154edcb3d427fef64cb00ec0aff079c9d156ec46f29"
  license "Zlib"
  head "https://git.code.sf.net/p/optipng/code.git", branch: "tmp/main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "454b5f9b6d49bf650680ef1def5d18993bbe5e1748ece4d59cdbed4e278ac610"
  end

  depends_on "libpng"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "./configure", "--with-system-zlib",
                          "--with-system-libpng",
                          "--prefix=#{prefix}",
                          "--mandir=#{man}"
    system "make", "install"
  end

  test do
    system bin/"optipng", "-simulate", test_fixtures("test.png")
  end
end
