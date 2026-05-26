class RipgrepAll < Formula
  desc "Wrapper around ripgrep that adds multiple rich file types"
  homepage "https://github.com/phiresky/ripgrep-all"
  url "https://github.com/phiresky/ripgrep-all/archive/refs/tags/v0.10.10.tar.gz"
  sha256 "17fadc7b73a51608d57f82b4a11f3edc0da87716cc4b302103eed9d4b9010fe5"
  license "AGPL-3.0-or-later"
  head "https://github.com/phiresky/ripgrep-all.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "74eda730f7c6fd9680e16b2f8fc52e9642372edb366d4cd55794f463b8b9fe61"
  end

  depends_on "rust" => :build
  depends_on "ripgrep"

  uses_from_macos "zip" => :test

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    (testpath/"file.txt").write("Hello World")
    system "zip", "archive.zip", "file.txt"

    output = shell_output("#{bin}/rga 'Hello World' #{testpath}")
    assert_match "Hello World", output
  end
end
