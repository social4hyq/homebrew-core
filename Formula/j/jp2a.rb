class Jp2a < Formula
  desc "Convert JPG images to ASCII"
  homepage "https://github.com/Talinx/jp2a"
  url "https://github.com/Talinx/jp2a/releases/download/v1.3.3/jp2a-1.3.3.tar.bz2"
  sha256 "8aa995f570235321c94dcf705ca12d3e499f2a6b78213698de3c152534e38c0e"
  license "GPL-2.0-or-later"
  revision 1
  version_scheme 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c946122c3e8960694e9b0fdf3e749ba46e1f745ef77bac64684b1e59ba822b9f"
  end

  depends_on "pkgconf" => :build
  depends_on "jpeg-turbo"
  depends_on "libexif"
  depends_on "libpng"
  depends_on "webp"

  uses_from_macos "curl"
  uses_from_macos "ncurses"

  def install
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"jp2a", test_fixtures("test.jpg")
  end
end
