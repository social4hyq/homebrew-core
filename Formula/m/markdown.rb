class Markdown < Formula
  desc "Text-to-HTML conversion tool"
  homepage "https://daringfireball.net/projects/markdown/"
  url "https://daringfireball.net/projects/downloads/Markdown_1.0.1.zip"
  sha256 "6520e9b6a58c5555e381b6223d66feddee67f675ed312ec19e9cee1b92bc0137"
  license "BSD-3-Clause"

  livecheck do
    url :homepage
    regex(/href=.*?Markdown[._-]v?(\d+(?:\.\d+)+)\.zip/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d8f63e55917e1fae6cffb2ea55d12f5a24cbb43fbfc51f1965246f8a3f979146"
  end

  conflicts_with "discount", because: "both install `markdown` binaries"
  conflicts_with "multimarkdown", because: "both install `markdown` binaries"

  def install
    bin.install "Markdown.pl" => "markdown"
  end

  test do
    assert_equal "<p>foo <em>bar</em></p>\n", pipe_output(bin/"markdown", "foo *bar*\n")
  end
end
