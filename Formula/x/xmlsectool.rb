class Xmlsectool < Formula
  desc "Check schema validity and signature of an XML document"
  homepage "https://wiki.shibboleth.net/confluence/display/XSTJ3/xmlsectool+V3+Home"
  url "https://shibboleth.net/downloads/tools/xmlsectool/4.0.0/xmlsectool-4.0.0-bin.zip"
  sha256 "32a5fd3c92cddb7833249e22c97253fbbf02ae2dc0a385896e6e7ac1d1a77de4"
  license "Apache-2.0"
  revision 2

  livecheck do
    url "https://shibboleth.net/downloads/tools/xmlsectool/latest/"
    regex(/href=.*?xmlsectool[._-]v?(\d+(?:\.\d+)+)(?:-bin)?\.zip/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d6804a03398a935e5b101ae696c3363a206915ba732d5695b046b1802cdecd8e"
  end

  depends_on "openjdk"
  depends_on "bash"

  def install
    prefix.install "doc/LICENSE.txt"
    rm_r("doc")
    libexec.install Dir["*"]
    # Fix shebang: HarmonyOS doesn't have /bin/bash
    inreplace libexec/"xmlsectool.sh", "#! /bin/bash", "#!#{Formula["bash"].opt_bin}/bash"
    (bin/"xmlsectool").write_env_script "#{libexec}/xmlsectool.sh", JAVA_HOME: Formula["openjdk"].opt_prefix
  end

  test do
    system bin/"xmlsectool", "--listAlgorithms"
  end
end
