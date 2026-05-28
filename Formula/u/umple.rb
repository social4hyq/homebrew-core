class Umple < Formula
  desc "Modeling tool/programming language that enables Model-Oriented Programming"
  homepage "https://cruise.umple.org/umple/"
  url "https://github.com/umple/umple/releases/download/v1.37.0/umple-1.37.0.8542.3a8c87689.jar"
  version "1.37.0"
  sha256 "a411c76d445b7bb079035d6d4a1bc71a548ee173093dc74cec8cbea61dcfc401"
  license "MIT"
  version_scheme 1

  livecheck do
    url :stable
    strategy :github_latest
  end

  no_autobump! because: :incompatible_version_format

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7e28d8adad0d1fec26385ecfd08313e75c23710a37f1bf6d7571e386885f93b9"
  end

  depends_on "openjdk"

  def install
    filename = File.basename(stable.url)

    libexec.install filename
    bin.write_jar_script libexec/filename, "umple"
  end

  test do
    (testpath/"test.ump").write("class X{ a; }")
    system bin/"umple", "test.ump", "-c", "-"
    assert_path_exists testpath/"X.java"
    assert_path_exists testpath/"X.class"
  end
end
