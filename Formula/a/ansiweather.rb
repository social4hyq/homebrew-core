class Ansiweather < Formula
  desc "Weather in your terminal, with ANSI colors and Unicode symbols"
  homepage "https://github.com/fcambus/ansiweather"
  url "https://github.com/fcambus/ansiweather/archive/refs/tags/1.19.1.tar.gz"
  sha256 "a3087857b014ecf46203f955c0146e6392db570a220395cfbf6b8d1587ad54c4"
  license "BSD-2-Clause"
  head "https://github.com/fcambus/ansiweather.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6d7b1b6ba9491f3afeeae109d8d19d2c26a60b782da2749e9de9782dfd990876"
  end

  uses_from_macos "bc-gh"
  uses_from_macos "jq", since: :sequoia

  def install
    bin.install "ansiweather"
    man1.install "ansiweather.1"
  end

  test do
    assert_match "Wind", shell_output(bin/"ansiweather")
  end
end
