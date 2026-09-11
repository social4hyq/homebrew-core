class Kawa < Formula
  desc "Programming language for Java (implementation of Scheme)"
  homepage "https://www.gnu.org/software/kawa/"
  url "https://ftpmirror.gnu.org/gnu/kawa/kawa-3.1.1.zip"
  mirror "https://ftp.gnu.org/gnu/kawa/kawa-3.1.1.zip"
  sha256 "dab1f41da968191fc68be856f133e3d02ce65d2dbd577a27e0490f18ca00fa22"
  license "MIT"
  revision 2

  livecheck do
    url :stable
    regex(/href=.*?kawa[._-]v?(\d+(?:\.\d+)+)\.(?:t|zip)/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "79d2600c0613f37c3d1f45d3b12e7398f420f03e6079012206a4f3c9950d2e1d"
  end

  depends_on "openjdk"

  def install
    rm Dir["bin/*.bat"]
    inreplace "bin/kawa", "thisfile=`command -v $0`",
                          "thisfile=#{libexec}/bin/kawa"
    libexec.install "bin", "lib"
    (bin/"kawa").write_env_script libexec/"bin/kawa", JAVA_HOME: Formula["openjdk"].opt_prefix
    doc.install Dir["doc/*"]
  end

  test do
    system bin/"kawa", "-e", "(import (srfi 1))"
  end
end
