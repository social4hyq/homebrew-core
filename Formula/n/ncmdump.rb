class Ncmdump < Formula
  desc "Convert Netease Cloud Music ncm files to mp3/flac files"
  homepage "https://github.com/taurusxin/ncmdump"
  url "https://github.com/taurusxin/ncmdump/archive/refs/tags/1.5.1.tar.gz"
  sha256 "35062836d5210718b12fd311535f4673f5db4de18bd8e987890d89fc0e0a7e6c"
  license "MIT"
  head "https://github.com/taurusxin/ncmdump.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0c2d6913196b27aaef73a5ca620b2c6f4de5688e3a2d71af24f36bfc670a614c"
  end

  depends_on "cmake" => :build
  depends_on "taglib"

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    resource "homebrew-test" do
      url "https://raw.githubusercontent.com/taurusxin/ncmdump/516b31ab68f806ef388084add11d9e4b2253f1c7/test/test.ncm"
      sha256 "a1586bbbbad95019eee566411de58a57c3a3bd7c86d97f2c3c82427efce8964b"
    end

    resource("homebrew-test").stage(testpath)
    system bin/"ncmdump", testpath/"test.ncm"
    assert_path_exists testpath/"test.flac"
  end
end
