class Pdfrip < Formula
  desc "Multi-threaded PDF password cracking utility"
  homepage "https://github.com/mufeedvh/pdfrip"
  url "https://github.com/mufeedvh/pdfrip/archive/refs/tags/v3.0.0.tar.gz"
  sha256 "e75bb5bcc2b58f80189dd10ba18e3cb8673935316172b8bd7a63822859cba11b"
  license "MIT"
  head "https://github.com/mufeedvh/pdfrip.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1a49d8920ccd064d6a08cc26d47cf885c336d4910565f186f9012e9baf70592d"
  end

  depends_on "cmake" => :build
  depends_on "rust" => :build

  def install
    ENV["SDKROOT"] = MacOS.sdk_path if OS.mac?

    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/pdfrip --version")

    output = shell_output("#{bin}/pdfrip -f #{test_fixtures("test.pdf")} range 1 5 2>&1", 1)
    assert_match "PDF is not encrypted with the Standard password-based security handler", output
  end
end
