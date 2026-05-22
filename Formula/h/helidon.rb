class Helidon < Formula
  desc "Command-line tool for Helidon application development"
  homepage "https://helidon.io/"
  url "https://github.com/helidon-io/helidon-build-tools/archive/refs/tags/3.0.6.tar.gz"
  sha256 "749cf3fd162bb9449ab57584c0bdf8874114d678499071ea522c047637de0f90"
  license "Apache-2.0"
  revision 1

  # There can be a notable gap between when a version is tagged and a
  # corresponding release is created, so we check the "latest" release instead
  # of the Git tags.
  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "03d007c996780318d498a73b395a3526bab3f72bdee6bf3cc071711f3fb933f6"
  end

  depends_on "maven"
  depends_on "openjdk"

  def install
    system "mvn", "package", "-f", "cli/impl/pom.xml", "-DskipTests"
    system "unzip", "cli/impl/target/helidon-cli"
    libexec.install "helidon-#{version}/bin", "helidon-#{version}/helidon-cli.jar", "helidon-#{version}/libs"
    (bin/"helidon").write_env_script libexec/"bin/helidon", Language::Java.overridable_java_home_env
  end

  test do
    # Avoid error: java.lang.IllegalArgumentException: `HOMEBREW_CACHE/"java_cache"` does not exist
    mkdir_p HOMEBREW_CACHE/"java_cache"

    system bin/"helidon", "init", "--batch"
    assert_predicate testpath/"quickstart-se", :directory?
  end
end
