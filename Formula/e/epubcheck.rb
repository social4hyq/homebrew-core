class Epubcheck < Formula
  desc "Validate EPUB files, version 2.0 and later"
  homepage "https://github.com/w3c/epubcheck"
  url "https://github.com/w3c/epubcheck/releases/download/v5.3.0/epubcheck-5.3.0.zip"
  sha256 "6c07e68584b2e2ce2f89fe06e1246dfead3eb36b46b340e7d93524f29dcff6c5"
  license "BSD-3-Clause"
  revision 1

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c1bb37e3b5bb6dcae20d9712d6de60b71f67868dbaafa142fdca647dc160e3c7"
  end

  depends_on "openjdk"

  def install
    jarname = "epubcheck.jar"
    libexec.install jarname, "lib"
    bin.write_jar_script libexec/jarname, "epubcheck"
  end

  test do
    assert_match "No errors or warnings detected", shell_output("#{bin}/epubcheck #{test_fixtures("test.epub")}")
  end
end
