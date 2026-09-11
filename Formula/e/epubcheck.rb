class Epubcheck < Formula
  desc "Validate EPUB files, version 2.0 and later"
  homepage "https://github.com/w3c/epubcheck"
  url "https://github.com/w3c/epubcheck/releases/download/v5.3.0/epubcheck-5.3.0.zip"
  sha256 "6c07e68584b2e2ce2f89fe06e1246dfead3eb36b46b340e7d93524f29dcff6c5"
  license "BSD-3-Clause"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7009610782ae59cb3c0bce7d7f385be428d9c9d0851e81f7172702bc99b8dad4"
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
