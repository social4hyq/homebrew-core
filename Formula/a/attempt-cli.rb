class AttemptCli < Formula
  desc "CLI for retrying fallible commands"
  homepage "https://github.com/MaxBondABE/attempt"
  url "https://github.com/MaxBondABE/attempt/archive/refs/tags/v1.1.1.tar.gz"
  sha256 "95c0d7873db135361f5de50e1add0aa472f543dd499aec3cd1fda678672c850a"
  license "Unlicense"
  head "https://github.com/MaxBondABE/attempt.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6b574a9f222745cdf2d672cfd6d06ed8080e6c55f674b2146d6a5ee6dbf962ef"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/attempt --version")

    output = shell_output("#{bin}/attempt fixed -a 1 -m 0s -- sh -c 'echo ok'")
    assert_match "ok", output
  end
end
