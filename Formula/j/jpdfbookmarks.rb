class Jpdfbookmarks < Formula
  desc "Create and edit bookmarks on existing PDF files"
  homepage "https://sourceforge.net/projects/jpdfbookmarks/"
  url "https://downloads.sourceforge.net/project/jpdfbookmarks/JPdfBookmarks-2.5.2/jpdfbookmarks-2.5.2.tar.gz"
  sha256 "8ab51c20414591632e48ad3817e6c97e9c029db8aaeff23d74c219718cfe19f9"
  license "GPL-3.0-or-later"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9fdcc24c8686e6b698ed6b8e463af440afc8a6aa43643c038b02654872e7f25d"
  end

  depends_on "openjdk"

  def install
    libexec.install Dir["jpdfbookmarks.jar", "lib"]
    bin.write_jar_script libexec/"jpdfbookmarks.jar", "jpdfbookmarks"
  end

  test do
    test_bookmark = "Test/1,Black,notBold,notItalic,open,FitPage"
    (testpath/"in.txt").write(test_bookmark)

    system bin/"jpdfbookmarks", test_fixtures("test.pdf"), "-a", "in.txt", "-o", "out.pdf"
    assert_path_exists testpath/"out.pdf"

    assert_equal test_bookmark, shell_output("#{bin}/jpdfbookmarks out.pdf -d").strip
  end
end
