class Apng2gif < Formula
  desc "Convert APNG animations into animated GIF format"
  homepage "https://apng2gif.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/apng2gif/1.8/apng2gif-1.8-src.zip"
  sha256 "9a07e386017dc696573cd7bc7b46b2575c06da0bc68c3c4f1c24a4b39cdedd4d"
  license all_of: ["libpng-2.0", "Zlib"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7dae003488294b89de532bc18db9ddac675f0f8095fcab72c771d5647354412a"
  end

  depends_on "libpng"

  def install
    system "make"
    bin.install "apng2gif"
  end

  test do
    cp test_fixtures("test.png"), testpath/"test.png"
    system bin/"apng2gif", testpath/"test.png"
    assert_path_exists testpath/"test.gif", "Failed to create test.gif"
  end
end
