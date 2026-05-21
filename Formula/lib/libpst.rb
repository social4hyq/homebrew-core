class Libpst < Formula
  desc "Utilities for the PST file format"
  homepage "https://www.five-ten-sg.com/libpst/"
  url "https://www.five-ten-sg.com/libpst/packages/libpst-0.6.76.tar.gz"
  sha256 "3d291beebbdb48d2b934608bc06195b641da63d2a8f5e0d386f2e9d6d05a0b42"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://www.five-ten-sg.com/libpst/packages/"
    regex(/href=.*?libpst[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7550e9d21548407cd743927cd7ec22ad7fce1ac48cb7154a631be62c37e63d4f"
  end

  depends_on "pkgconf" => :build

  depends_on "glib"
  depends_on "libgsf"

  on_macos do
    depends_on "gettext"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "./configure", "--disable-python", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"lspst", "-V"
  end
end
