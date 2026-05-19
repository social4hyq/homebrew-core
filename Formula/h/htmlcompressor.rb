class Htmlcompressor < Formula
  desc "Minify HTML or XML"
  homepage "https://code.google.com/archive/p/htmlcompressor/"
  url "https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/htmlcompressor/htmlcompressor-1.5.3.jar"
  sha256 "88894e330cdb0e418e805136d424f4c262236b1aa3683e51037cdb66310cb0f9"
  license "Apache-2.0"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d379a203ca821f197e80c51662e1f124c02b9a00fe189d1cb12b438050f5aa84"
  end

  depends_on "openjdk"

  def install
    libexec.install "htmlcompressor-#{version}.jar"
    bin.write_jar_script libexec/"htmlcompressor-#{version}.jar", "htmlcompressor"
  end

  test do
    path = testpath/"index.xml"
    path.write <<~EOS
      <foo>
        <bar /> <!-- -->
      </foo>
    EOS

    output = shell_output("#{bin}/htmlcompressor #{path}").strip
    assert_equal "<foo><bar/></foo>", output
  end
end
