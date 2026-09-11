class DitaOt < Formula
  desc "DITA Open Toolkit is an implementation of the OASIS DITA specification"
  homepage "https://www.dita-ot.org/"
  url "https://github.com/dita-ot/dita-ot/releases/download/4.4.1/dita-ot-4.4.1.zip"
  sha256 "154414c1debb548e923bf77e9a09019e249a8887680ff4bfbd8e137de9e8e250"
  license "Apache-2.0"
  revision 1

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2404cd9d995840490fb2bf202da2ddd42afba77fe26bb100a1b4cf97fc4e41a2"
  end

  depends_on "openjdk"

  def install
    rm(Dir["bin/*.bat", "config/env.bat", "startcmd.*"])
    libexec.install Dir["*"]
    (bin/"dita").write_env_script libexec/"bin/dita", JAVA_HOME: Formula["openjdk"].opt_prefix

    # Build an `:all` bottle by removing doc file.
    rm libexec/"docsrc/topics/installing-via-homebrew.dita"
  end

  test do
    system bin/"dita", "--input=#{libexec}/docsrc/site.ditamap",
                       "--format=html5",
                       "--output=#{testpath}/out"
    assert_path_exists testpath/"out/index.html"
  end
end
