class Tfocus < Formula
  desc "Tool for selecting and executing terraform plan/apply on specific resources"
  homepage "https://github.com/nwiizo/tfocus"
  url "https://github.com/nwiizo/tfocus/archive/refs/tags/v0.1.5.tar.gz"
  sha256 "cf8d841d170c551e8f669e8fe71b5c85f0f2b36623ca6e2b8189aa041e76b75d"
  license "MIT"
  head "https://github.com/nwiizo/tfocus.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ef35ee6f832ff8902773e42745dac0d6114c261b7046c456a60b062066c984a3"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tfocus --version")

    output = shell_output("#{bin}/tfocus 2>&1", 1)
    assert_match "No Terraform files found in the current directory", output
  end
end
