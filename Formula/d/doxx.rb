class Doxx < Formula
  desc "Terminal document viewer for .docx files"
  homepage "https://github.com/bgreenwell/doxx"
  url "https://github.com/bgreenwell/doxx/archive/refs/tags/v0.1.4.tar.gz"
  sha256 "72af676ca30b27adc7a13b17a48aac88589c940accba28453f3d94a861bed961"
  license "MIT"
  head "https://github.com/bgreenwell/doxx.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "555f47cb54596cf8513fc27820a8d10e3a91f70f19e4d7c1868578d1406b4a30"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    system bin/"generate_test_docs"
    assert_path_exists testpath/"tests/fixtures/minimal.docx"

    output = shell_output("#{bin}/doxx #{testpath}/tests/fixtures/minimal.docx")
    assert_match <<~EOS, output
      Document: minimal
      Pages: 1
      Words: 26
    EOS
  end
end
