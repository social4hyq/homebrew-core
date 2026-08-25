class Dtop < Formula
  desc "Terminal dashboard for Docker monitoring across multiple hosts"
  homepage "https://dtop.dev/"
  url "https://github.com/amir20/dtop/archive/refs/tags/v0.9.0.tar.gz"
  sha256 "6ef13284e757379fcc2c6ebba5c9676338ac0ec3df629196896e63b2b4ffe063"
  license "MIT"
  head "https://github.com/amir20/dtop.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e67637853d95e6ef05c6853e18194e55785d2e06451c6b1a16244c9a8e5b21bc"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dtop --version")

    output = shell_output("#{bin}/dtop 2>&1", 1)
    assert_match "Failed to connect to Docker host", output
  end
end
