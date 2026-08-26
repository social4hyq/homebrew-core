class Feh < Formula
  desc "X11 image viewer"
  homepage "https://feh.finalrewind.org/"
  url "https://feh.finalrewind.org/feh-3.12.3.tar.bz2"
  sha256 "2236c21c2a02e1cc291c0d8827414433fcd26c260a60fb385a819e3af600cc75"
  license "MIT-feh"

  livecheck do
    url :homepage
    regex(/href=.*?feh[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "211ebbffa0d30e24c8706e248c68cdd13d86702cc44a730c2dfe5c4deec63a7e"
  end

  depends_on "imlib2"
  depends_on "libexif"
  depends_on "libpng"
  depends_on "libx11"
  depends_on "libxinerama"
  depends_on "libxt"

  uses_from_macos "curl"

  def install
    system "make", "PREFIX=#{prefix}", "verscmp=0", "exif=1"
    system "make", "PREFIX=#{prefix}", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/feh -v")
  end
end
