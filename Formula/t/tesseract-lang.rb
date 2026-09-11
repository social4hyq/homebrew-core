class TesseractLang < Formula
  desc "Enables extra languages support for Tesseract"
  homepage "https://github.com/tesseract-ocr/tessdata_fast/"
  url "https://github.com/tesseract-ocr/tessdata_fast/archive/refs/tags/4.1.0.tar.gz"
  sha256 "d0e3bb6f3b4e75748680524a1d116f2bfb145618f8ceed55b279d15098a530f9"
  license "Apache-2.0"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "130b161d7d40612428f06a4f6a5e2314c57524e3598a82479aa699c5fd55d140"
  end

  depends_on "tesseract"

  resource "testfile" do
    url "https://raw.githubusercontent.com/tesseract-ocr/test/6dd816cdaf3e76153271daf773e562e24c928bf5/testing/eurotext.tif"
    sha256 "7b9bd14aba7d5e30df686fbb6f71782a97f48f81b32dc201a1b75afe6de747d6"
  end

  def install
    rm "eng.traineddata"
    rm "osd.traineddata"
    (share/"tessdata").install Dir["*"]
  end

  test do
    resource("testfile").stage do
      system "#{Formula["tesseract"].bin}/tesseract", "./eurotext.tif", "./output", "-l", "eng+deu"
      assert_match "über den faulen Hund. Le renard brun\n", File.read("output.txt")
    end
  end
end
