class ForkCleaner < Formula
  desc "Cleans up old and inactive forks on your GitHub account"
  homepage "https://github.com/caarlos0/fork-cleaner"
  url "https://github.com/caarlos0/fork-cleaner/archive/refs/tags/v2.4.0.tar.gz"
  sha256 "28ded4826d8a36d25857b824bea1ae480c76029ff50e8d831f79e18c360ff032"
  license "MIT"
  head "https://github.com/caarlos0/fork-cleaner.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "62841349f5b2312f8ce8c41ca2d554302b632c7a7ecc4019801430e73034199a"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}"), "./cmd/fork-cleaner"
  end

  test do
    output = shell_output("#{bin}/fork-cleaner 2>&1", 1)
    assert_match "missing github token", output
  end
end
