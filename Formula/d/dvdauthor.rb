class Dvdauthor < Formula
  desc "DVD-authoring toolset"
  homepage "https://dvdauthor.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/dvdauthor/dvdauthor-0.7.2.tar.gz"
  sha256 "3020a92de9f78eb36f48b6f22d5a001c47107826634a785a62dfcd080f612eb7"
  license "GPL-2.0-or-later"
  revision 4

  livecheck do
    url :stable
    regex(%r{url=.*?/dvdauthor[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c2ecfcabee36c79eea3f23a2902c9932a4ce7a9b8c9a222c22a9e4fadb221be9"
  end

  # Dvdauthor will optionally detect ImageMagick or GraphicsMagick, too.
  # But we don't add either as deps because they are big.

  depends_on "pkgconf" => :build
  depends_on "freetype"
  depends_on "libdvdread"
  depends_on "libpng"

  uses_from_macos "libxml2"

  def install
    system "./configure", "--mandir=#{man}", *std_configure_args
    system "make"
    ENV.deparallelize # Install isn't parallel-safe
    system "make", "install"
  end

  test do
    assert_match "VOBFILE", shell_output("#{bin}/dvdauthor --help 2>&1", 1)
  end
end
