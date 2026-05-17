class BwmNg < Formula
  desc "Console-based live network and disk I/O bandwidth monitor"
  homepage "https://www.gropp.org/?id=projects&sub=bwm-ng"
  url "https://github.com/vgropp/bwm-ng/archive/refs/tags/v0.6.3.tar.gz"
  sha256 "c1a552b6ff48ea3e4e10110a7c188861abc4750befc67c6caaba8eb3ecf67f46"
  license "GPL-2.0-or-later"
  head "https://github.com/vgropp/bwm-ng.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "34b29f7f49524c2185729d49b1175c724bd9a676a1cc17823a985f9b85c44fe4"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  def install
    ENV.append "CFLAGS", "-std=gnu89"

    system "./autogen.sh"
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    assert_match "<div class=\"bwm-ng-header\">", shell_output("#{bin}/bwm-ng -o html")
  end
end
