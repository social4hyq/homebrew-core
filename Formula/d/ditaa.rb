class Ditaa < Formula
  desc "Convert ASCII diagrams into proper bitmap graphics"
  homepage "https://ditaa.sourceforge.net/"
  url "https://github.com/stathissideris/ditaa/releases/download/v0.11.0/ditaa-0.11.0-standalone.jar"
  sha256 "9418aa63ff6d89c5d2318396f59836e120e75bea7a5930c4d34aa10fe7a196a9"
  license "LGPL-3.0-or-later"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "143909143a3c3f4fb26b52362199e64829a05d70d093084c365374e4963e7ede"
  end

  depends_on "openjdk"

  def install
    libexec.install "ditaa-#{version}-standalone.jar"
    bin.write_jar_script libexec/"ditaa-#{version}-standalone.jar", "ditaa"
  end

  test do
    system bin/"ditaa", "-help"
  end
end
