class Libcdio < Formula
  desc "Compact Disc Input and Control Library"
  homepage "https://savannah.gnu.org/projects/libcdio/"
  url "https://github.com/libcdio/libcdio/releases/download/2.4.0/libcdio-2.4.0.tar.gz"
  sha256 "bf7cde63762bb12db7755c395c441e49406fde7e1d9f9a9be7e3b940b1f405d7"
  license "GPL-3.0-or-later"
  revision 1
  compatibility_version 1

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b4a8ab6ccce8a9795704caef86196b9f9b141f8a408186b6f9e29c8fe329dbc3"
  end

  depends_on "pkgconf" => :build

  def install
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/cd-info -v", 1)
  end
end
