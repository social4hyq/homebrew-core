class Denominator < Formula
  desc "Portable Java library for manipulating DNS clouds"
  homepage "https://github.com/Netflix/denominator/tree/v4.7.1/cli"
  url "https://search.maven.org/remotecontent?filepath=com/netflix/denominator/denominator-cli/4.7.1/denominator-cli-4.7.1-fat.jar"
  sha256 "f2d09aaebb63ccb348dcba3a5cc3e94a42b0eae49e90ac0ec2b0a14adfbe5254"
  license "Apache-2.0"

  livecheck do
    url "https://search.maven.org/remotecontent?filepath=com/netflix/denominator/denominator-cli/maven-metadata.xml"
    regex(%r{<version>v?(\d+(?:\.\d+)+)</version>}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3e4d92d2ebdcf993a4569902547f1504a32d70c2458260be3fbcdb8c300b2d49"
  end

  depends_on "openjdk"

  def install
    (libexec/"bin").install "denominator-cli-#{version}-fat.jar"
    bin.write_jar_script libexec/"bin/denominator-cli-#{version}-fat.jar", "denominator"
  end

  test do
    system bin/"denominator", "providers"
  end
end
