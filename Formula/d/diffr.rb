class Diffr < Formula
  desc "LCS based diff highlighting tool to ease code review from your terminal"
  homepage "https://github.com/mookid/diffr"
  url "https://github.com/mookid/diffr/archive/refs/tags/v0.1.5.tar.gz"
  sha256 "6c5861e5b8f5d798e027fe69cc186452848dc4ae5641326b41b5c160d3e91654"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8a97aa862fc899bd39c663add0d6622d5f7db80f7f6d125e1a8572fba0e49179"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    output = pipe_output("#{bin}/diffr --colors refine-added:none --colors added:foreground:blue", <<~DIFF, 0)
      @@ -1 +1,2 @@
       foo
      +bar
    DIFF

    assert_equal <<~DIFF, output
      \e[0m@@ -1 +1,2 @@\e[0m
      \e[0m foo\e[0m
      \e[0m\e[34m+\e[0m\e[0mbar\e[0m
    DIFF
  end
end
