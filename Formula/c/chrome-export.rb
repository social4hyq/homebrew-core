class ChromeExport < Formula
  include Language::Python::Shebang

  desc "Convert Chrome's bookmarks and history to HTML bookmarks files"
  homepage "https://github.com/bdesham/chrome-export"
  url "https://github.com/bdesham/chrome-export/archive/refs/tags/v2.0.2.tar.gz"
  sha256 "41b667b407bc745a57105cc7969ec80cd5e50d67e1cce73cf995c2689d306e97"
  license "ISC"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9943bc14c1a52685b513b030ed76edea2a9857d688b8494ad729196539068830"
  end

  uses_from_macos "python"

  def install
    bin.install "export-chrome-bookmarks", "export-chrome-history"
    rewrite_shebang detected_python_shebang(use_python_from_path: true), *bin.children

    man1.install buildpath.glob("man_pages/*.1")
    pkgshare.install "test"
  end

  test do
    cp_r (pkgshare/"test").children, testpath
    system bin/"export-chrome-bookmarks", "Bookmarks",
           "bookmarks_actual_output.html"
    assert_path_exists testpath/"bookmarks_actual_output.html"
    assert_equal (testpath/"bookmarks_expected_output.html").read,
                 (testpath/"bookmarks_actual_output.html").read
    system bin/"export-chrome-history", "History", "history_actual_output.html"
    assert_path_exists testpath/"history_actual_output.html"
    assert_equal (testpath/"history_expected_output.html").read,
                 (testpath/"history_actual_output.html").read
  end
end
