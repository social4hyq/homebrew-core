class Jslint4java < Formula
  desc "Java wrapper for JavaScript Lint (jsl)"
  homepage "https://code.google.com/archive/p/jslint4java/"
  url "https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/jslint4java/jslint4java-2.0.5-dist.zip"
  sha256 "078240b17256a0472f9981d68f11556238658ebaa67be49ea49958adafc96a81"
  license "BSD-2-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0c1d9c1b31aa438a7280d287fc7ff3c29952b9eed7b3d4ac125cd46f66286085"
  end

  depends_on "openjdk"

  def install
    doc.install Dir["docs/*"]
    libexec.install Dir["*.jar"]
    bin.write_jar_script Dir[libexec/"jslint4java*.jar"].first, "jslint4java"
  end

  test do
    path = testpath/"test.js"
    path.write <<~EOS
      var i = 0;
      var j = 1  // no semicolon
    EOS
    output = shell_output("#{bin}/jslint4java #{path}", 1)
    assert_match "2:10:Expected ';' and instead saw '(end)'", output
  end
end
