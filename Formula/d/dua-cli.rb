class DuaCli < Formula
  desc "View disk space usage and delete unwanted data, fast"
  homepage "https://lib.rs/crates/dua-cli"
  url "https://github.com/Byron/dua-cli/archive/refs/tags/v2.41.0.tar.gz"
  sha256 "8163cdbdba2cc8e35450a31c64b7a334b6b1f22a07ae737824e355ddd896de19"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "49c53684e6ff090f2d77da8c31e8a50c77ba0f25f6de8a8bc7787654d36ad705"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    # Test that usage is correct for these 2 files.
    (testpath/"empty.txt").write("")
    (testpath/"file.txt").write("01")

    expected = %r{
      \e\[32m\s*0\s*B\e\[39m\ #{testpath}/empty.txt\n
      \e\[32m\s*2\s*B\e\[39m\ #{testpath}/file.txt\n
      \e\[32m\s*2\s*B\e\[39m\ total\n
    }x
    assert_match expected, shell_output("#{bin}/dua -A #{testpath}/*.txt")
  end
end
