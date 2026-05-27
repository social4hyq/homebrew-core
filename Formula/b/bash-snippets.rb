class BashSnippets < Formula
  desc "Collection of small bash scripts for heavy terminal users"
  homepage "https://github.com/alexanderepstein/Bash-Snippets"
  url "https://github.com/alexanderepstein/Bash-Snippets/archive/refs/tags/v1.23.0.tar.gz"
  sha256 "59b784e714ba34a847b6a6844ae1703f46db6f0a804c3e5f2de994bbe8ebe146"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "56d28aaa2b645764125233d7e424a18ffb2883e8912277ebd6efa6b8bb53cb9c"
  end

  conflicts_with "cheat", because: "both install `cheat` binaries"
  conflicts_with "expect", because: "both install `weather` binaries"
  conflicts_with "pwned", because: "both install `pwned` binaries"
  conflicts_with "todoman", because: "both install `todo` binaries"

  def install
    system "./install.sh", "--prefix=#{prefix}", "all"
  end

  test do
    output = shell_output("#{bin}/weather London").lines.first.chomp
    assert_equal "Weather report: London", output
    output = shell_output("#{bin}/qrify This is a test")
    assert_match "████ ▄▄▄▄▄ █▀▄█▀ █  ▀█ ▄▄▄▄▄ ████", output
  end
end
