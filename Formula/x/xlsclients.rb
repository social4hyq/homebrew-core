class Xlsclients < Formula
  desc "List client applications running on a display"
  homepage "https://gitlab.freedesktop.org/xorg/app/xlsclients"
  url "https://www.x.org/archive/individual/app/xlsclients-1.1.6.tar.xz"
  sha256 "909810a3fdbd01d84747907f2c0cc32ee732e77afc88cb310abb9d155b2a0807"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d6208715db73041ebf24fff2f3c114d3a30f727fcd7e48e57583216e13ceaf6d"
  end

  depends_on "pkgconf" => :build
  depends_on "libxcb"

  def install
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    output = shell_output("#{bin}/xlsclients -display :100 2>&1", 1)
    assert_match "xlsclients:  unable to open display", output
  end
end
