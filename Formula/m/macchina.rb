class Macchina < Formula
  desc "System information fetcher, with an emphasis on performance and minimalism"
  homepage "https://github.com/Macchina-CLI/macchina"
  url "https://github.com/Macchina-CLI/macchina/archive/refs/tags/v6.4.0.tar.gz"
  sha256 "edd7591565f199c1365420655a144507bcd2838aed09b79fefdc8b661180432f"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5afa91d5e453722b68d0dcd1fb80c882b106154add71dbb4a6935acb4d6efcd5"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match "We've collected a total of 19 readouts", shell_output("#{bin}/macchina --doctor")

    assert_match version.to_s, shell_output("#{bin}/macchina --version")
  end
end
