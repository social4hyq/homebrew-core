class Psftools < Formula
  desc "Tools for fixed-width bitmap fonts"
  homepage "https://www.seasip.info/Unix/PSF/"
  # psftools-1.1.10.tar.gz (dated 2017) was a typo of 1.0.10 and has since been deleted.
  # You may still find it on some mirrors but it should not be used.
  url "https://www.seasip.info/Unix/PSF/psftools-1.0.14.tar.gz"
  sha256 "dcf8308fa414b486e6df7c48a2626e8dcb3c8a472c94ff04816ba95c6c51d19e"
  license "GPL-2.0-or-later"
  version_scheme 1

  # The development release on the homepage uses the same filename format as
  # the stable release (e.g., psftools-1.1.1.tar.gz). However, the "Development
  # Release" section comes before the "Stable Release" section, so we can use
  # this heading to anchor stable releases for now.
  livecheck do
    url :homepage
    regex(/Stable Release.+?href=.*?psftools[._-]v?(\d+(?:\.\d+)+)\.t/im)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f000fb1bd0821edece1f104822493500f4f1a244ab67a0ef1e3f3dfdcc0143d6"
  end

  # The `autoconf` dependency originates from 54cfae502ee4
  # which was meant to fix a bug in the `configure` script.
  # We add `automake` and `libtool` to run `autoreconf` to
  # work around the `-flat_namespace` bug. Our usual patches
  # don't work here because the install method called `autoconf`.
  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  resource "pc8x8font" do
    url "https://www.zone38.net/font/pc8x8.zip"
    sha256 "13a17d57276e9ef5d9617b2d97aa0246cec9b2d4716e31b77d0708d54e5b978f"
  end

  def install
    # Regenerate `configure` to fix `-flat_namespace`.
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--mandir=#{man}", *std_configure_args
    system "make", "install"
  end

  test do
    # The zip file has a fon in it, use fon2fnts to extract to fnt
    resource("pc8x8font").stage do
      system bin/"fon2fnts", "pc8x8.fon"
      assert_path_exists Pathname.pwd/"PC8X8_9.fnt"
    end
  end
end
