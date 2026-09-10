class Onigmo < Formula
  desc "Regular expressions library forked from Oniguruma"
  homepage "https://github.com/k-takata/Onigmo"
  url "https://github.com/k-takata/Onigmo/releases/download/Onigmo-6.2.0/onigmo-6.2.0.tar.gz"
  sha256 "c648496b5339953b925ebf44b8de356feda8d3428fa07dc1db95bfe2570feb76"
  license "BSD-2-Clause"
  revision 1
  head "https://github.com/k-takata/Onigmo.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2592053685f0ef2eb3b64eddb8572d7987dc4c2f209add1a6a2c0ad72aa69bb1"
  end

  def install
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    assert_match(/#{prefix}/, shell_output("#{bin}/onigmo-config --prefix"))
  end
end
