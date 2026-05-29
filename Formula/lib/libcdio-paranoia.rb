class LibcdioParanoia < Formula
  desc "CD paranoia on top of libcdio"
  homepage "https://github.com/libcdio/libcdio-paranoia"
  url "https://github.com/libcdio/libcdio-paranoia/releases/download/release-10.2%2B2.0.2/libcdio-paranoia-10.2+2.0.2.tar.gz"
  # Plus sign is not a valid version character
  version "10.2-2.0.2"
  sha256 "99488b8b678f497cb2e2f4a1a9ab4a6329c7e2537a366d5e4fef47df52907ff6"
  license "GPL-3.0-only"

  no_autobump! because: :incompatible_version_format

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e65a8f2817c75ec28da0dfb775b0e61c75d22e19314a25ac9a2411374b80f0f8"
  end

  depends_on "pkgconf" => :build
  depends_on "libcdio"

  def install
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    assert_match(/^cdparanoia /, shell_output("#{bin}/cd-paranoia -V 2>&1"))
    # Ensure it errors properly with no disc drive.
    assert_match(/Unable find or access a CD-ROM drive/, shell_output("#{bin}/cd-paranoia -BX 2>&1", 1))
  end
end
