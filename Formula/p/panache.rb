class Panache < Formula
  desc "Language server, formatter, and linter for Markdown, Quarto, and R Markdown"
  homepage "https://panache.bz"
  url "https://github.com/jolars/panache/archive/refs/tags/v2.60.0.tar.gz"
  sha256 "2d5d01c6793feee7d6abc081dc22c076ecd4591bf68e677f5ba8728469a2323c"
  license "MIT"
  head "https://github.com/jolars/panache.git", branch: "main"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "41c1e54622258f9dd486f967631f359d33db08a92e9e515d2c05f76fff82319e"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    input = <<~MARKDOWN
      # Heading

      * one
      * two
    MARKDOWN

    output = pipe_output("#{bin}/panache format -", input)
    assert_match "- one", output
    assert_match "- two", output
  end
end
