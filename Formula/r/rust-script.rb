class RustScript < Formula
  desc "Run Rust files and expressions as scripts without any setup or compilation step"
  homepage "https://rust-script.org"
  url "https://github.com/fornwall/rust-script/archive/refs/tags/0.36.0.tar.gz"
  sha256 "9b6d04ad4dd34838c1b55a8ec4b69e8d7f3008a67d85ef1c35b49502c359b6d8"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d4159c9a9d52be4de5a49305b71c1ea14d9c3bd3475827bc43225e68a4e61522"
  end

  depends_on "rust" => :no_linkage

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_equal "Hello, world!", shell_output("#{bin}/rust-script -e 'println!(\"Hello, world!\")'").strip
  end
end
