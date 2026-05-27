class Proguard < Formula
  desc "Java class file shrinker, optimizer, and obfuscator"
  homepage "https://www.guardsquare.com/en/products/proguard"
  url "https://github.com/Guardsquare/proguard/releases/download/v7.9.1/proguard-7.9.1.tar.gz"
  sha256 "2bae1c85d7d7353ce22f49e577e94a241c27f00af4b2aa2f78bd19d77d79d903"
  license "GPL-2.0-or-later"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "359729eeac7d9812f8cf607c94745d55b3712fce6e22b5a17d00713affbe8d3e"
  end

  depends_on "openjdk"

  conflicts_with cask: "android-commandlinetools", because: "both install `retrace` binaries"

  def install
    libexec.install "lib/proguard.jar"
    libexec.install "lib/proguardgui.jar"
    libexec.install "lib/retrace.jar"
    bin.write_jar_script libexec/"proguard.jar", "proguard"
    bin.write_jar_script libexec/"proguardgui.jar", "proguardgui"
    bin.write_jar_script libexec/"retrace.jar", "retrace"
  end

  test do
    expect = <<~EOS
      ProGuard, version #{version}
      Usage: java proguard.ProGuard [options ...]
    EOS
    assert_equal expect, shell_output(bin/"proguard", 1)

    expect = <<~EOS
      Picked up _JAVA_OPTIONS: #{ENV["_JAVA_OPTIONS"]}
      Usage: java proguard.retrace.ReTrace [-regex <regex>] [-allclassnames] [-verbose] <mapping_file> [<stacktrace_file>]
    EOS
    assert_match expect, pipe_output("#{bin}/retrace 2>&1")
  end
end
