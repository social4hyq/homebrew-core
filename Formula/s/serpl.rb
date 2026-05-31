class Serpl < Formula
  desc "Simple terminal UI for search and replace"
  homepage "https://github.com/yassinebridi/serpl"
  url "https://github.com/yassinebridi/serpl/archive/refs/tags/0.3.6.tar.gz"
  sha256 "d794e020e3e6535ac2c0cee3613ffb9122e4df7a47d4e5c466e8b35e59e08312"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d23da3045cca44f747c7a9c4bca8f1340092778055755ccccf0e95f2595122d0"
  end

  depends_on "rust" => :build
  depends_on "ripgrep"

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/serpl --version")

    assert_match "a value is required for '--project-root <PATH>' but none was supplied",
      shell_output("#{bin}/serpl --project-root 2>&1", 2)
  end
end
