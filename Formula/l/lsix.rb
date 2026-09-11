class Lsix < Formula
  desc "Shows thumbnails in terminal using sixel graphics"
  homepage "https://github.com/hackerb9/lsix"
  url "https://github.com/hackerb9/lsix/archive/refs/tags/1.9.1.tar.gz"
  sha256 "310e25389da13c19a0793adcea87f7bc9aa8acc92d9534407c8fbd5227a0e05d"
  # https://github.com/hackerb9/lsix/blob/1.9.1/lsix#L333-L341
  license any_of: ["GPL-3.0-or-later", "X11"]
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b14eee3d40b13bdbbce2b0a7857153bd622b45e8eeec10b7e17f034ff15d22d9"
  end

  depends_on "imagemagick"

  on_macos do
    depends_on "bash"
  end

  def install
    bin.install "lsix"
  end

  test do
    output = shell_output("#{bin}/lsix 2>&1")
    assert_match "Error: Your terminal does not report having sixel graphics support.", output
  end
end
