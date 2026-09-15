class Epubcheck < Formula
  desc "Validate EPUB files, version 2.0 and later"
  homepage "https://github.com/w3c/epubcheck"
  url "https://github.com/w3c/epubcheck/releases/download/v5.4.0/epubcheck-5.4.0.zip"
  sha256 "33350c61038e71dfb3d45a76aed04bf5481e6d5500cb780f6e98db8bbd15a28c"
  license "BSD-3-Clause"

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
