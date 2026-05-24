class Bingrep < Formula
  desc "Greps through binaries from various OSs and architectures"
  homepage "https://github.com/m4b/bingrep"
  url "https://github.com/m4b/bingrep/archive/refs/tags/v0.12.1.tar.gz"
  sha256 "8bf096df68736561b40f56cd1feb4834014cd11c0a28b33e74e818618c62e100"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b00107e157a74466a5f161773f39af92fa33ce4fe60217a436600eea2419b781"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    (testpath/"test.c").write <<~C
      int homebrew_test() {
        return 0;
      }
      int main() {
        return homebrew_test();
      }
    C
    system ENV.cc, testpath/"test.c"
    assert_match "homebrew_test", shell_output("#{bin}/bingrep a.out")
  end
end
