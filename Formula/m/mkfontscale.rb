class Mkfontscale < Formula
  desc "Create an index of scalable font files for X"
  homepage "https://www.x.org/"
  url "https://www.x.org/releases/individual/app/mkfontscale-1.2.4.tar.xz"
  sha256 "a01492a17a9b6c0ee3f92ee578850e305315b9f298da5f006a1cd4b51db01a5e"
  license "X11"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7d5eaf90f2d4c807d545b81f91efb973fcbb66d6f57a4bd7c326eb4d1c3cd30e"
  end

  depends_on "pkgconf" => :build
  depends_on "xorgproto" => :build

  depends_on "freetype"
  depends_on "libfontenc"

  uses_from_macos "bzip2"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    configure_args = %w[
      --with-bzip2
    ]

    system "./configure", *configure_args, *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    system bin/"mkfontscale"
    assert_path_exists testpath/"fonts.scale"
  end
end
