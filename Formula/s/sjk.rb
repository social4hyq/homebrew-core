class Sjk < Formula
  desc "Swiss Java Knife"
  homepage "https://github.com/aragozin/jvm-tools"
  url "https://search.maven.org/remotecontent?filepath=org/gridkit/jvmtool/sjk-plus/0.23/sjk-plus-0.23.jar"
  sha256 "6aab07cdf0ecad394e225a1f47d7342cb23bfd8b7d5c65c945f81835363ec937"
  license "Apache-2.0"
  revision 1

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6ebe0e5f766ce58f7b3a67c3bb2668a7cbbc96cf2757959a1dfd4a01d52ccb10"
  end

  depends_on "openjdk"

  def install
    libexec.install "sjk-plus-#{version}.jar"
    bin.write_jar_script libexec/"sjk-plus-#{version}.jar", "sjk"
  end

  test do
    system bin/"sjk", "jps"
  end
end
