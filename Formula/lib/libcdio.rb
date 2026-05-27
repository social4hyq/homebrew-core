class Libcdio < Formula
  desc "Compact Disc Input and Control Library"
  homepage "https://savannah.gnu.org/projects/libcdio/"
  url "https://github.com/libcdio/libcdio/releases/download/2.3.0/libcdio-2.3.0.tar.gz"
  sha256 "37bcb13296febbcff9dc4485834bac09212cb463c31fcea52f70ee1dd3a5a5de"
  license "GPL-3.0-or-later"
  compatibility_version 1

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "898d027ceedba5bdde07217ec12bf7e828c1ccdd8a68848f35ac6d8f603019c9"
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
