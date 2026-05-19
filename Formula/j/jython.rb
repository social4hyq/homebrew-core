class Jython < Formula
  desc "Python implementation written in Java (successor to JPython)"
  homepage "https://www.jython.org/"
  url "https://search.maven.org/remotecontent?filepath=org/python/jython-installer/2.7.4/jython-installer-2.7.4.jar"
  sha256 "6001f0741ed5f4a474e5c5861bcccf38dc65819e25d46a258cbc0278394a070b"
  license "PSF-2.0"

  livecheck do
    url "https://search.maven.org/remotecontent?filepath=org/python/jython-installer/"
    regex(%r{href=["']?v?(\d+(?:\.\d+)+)/?["' >]}i)
  end

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dbf91c52a659a34aeb394f1759796c732ed160f348a81595d27252a007400320"
  end

  depends_on "openjdk"

  def install
    system "java", "-jar", cached_download, "-s", "-d", libexec
    (bin/"jython").write_env_script libexec/"bin/jython", Language::Java.overridable_java_home_env
  end

  test do
    jython = shell_output("#{bin}/jython -c \"from java.util import Date; print Date()\"")
    # This will break in the year 2100. The test will need updating then.
    assert_match jython.match(/20\d\d/).to_s, shell_output("/bin/date +%Y")
  end
end
