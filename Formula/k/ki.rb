class Ki < Formula
  desc "Kotlin Language Interactive Shell"
  homepage "https://github.com/Kotlin/kotlin-interactive-shell"
  url "https://github.com/Kotlin/kotlin-interactive-shell/archive/refs/tags/v0.5.2.tar.gz"
  sha256 "5b65d784a66b6e7aa7e6bc427e2886435747cb9b2969f239d3be1f2190929fe7"
  license "Apache-2.0"
  revision 1
  head "https://github.com/Kotlin/kotlin-interactive-shell.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bc547d627ddefe1293fc8c10078f47d7a0f3f3ac3d7d5ef241a5a891eba124f8"
  end

  # not compatible with kotlin 2.0+, https://github.com/Kotlin/kotlin-interactive-shell/issues/131
  deprecate! date: "2025-10-26", because: :unmaintained
  disable! date: "2026-10-26", because: :unmaintained

  depends_on "maven" => :build
  depends_on "openjdk@21"

  def install
    ENV["JAVA_HOME"] = Language::Java.java_home("21")

    system "mvn", "-DskipTests", "package"
    libexec.install "lib/ki-shell.jar"
    bin.write_jar_script libexec/"ki-shell.jar", "ki", java_version: "21"
  end

  test do
    output = pipe_output(bin/"ki", ":q")
    assert_match "ki-shell", output
    assert_match "Bye!", output
  end
end
