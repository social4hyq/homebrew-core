class Ali < Formula
  desc "Generate HTTP load and plot the results in real-time"
  homepage "https://github.com/nakabonne/ali"
  url "https://github.com/nakabonne/ali/archive/refs/tags/v0.8.0.tar.gz"
  sha256 "faf94ef7e0daa6d51b7064dd9757d4216168b19ed03c145ebf30e18f99fc81ad"
  license "MIT"
  head "https://github.com/nakabonne/ali.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6558b780acb82e74654fffcbe65c0366c3c13c236fadae1f3f996a118b827a98"
  end

  depends_on "go" => :build

  conflicts_with "nmh", because: "both install `ali` binaries"

  def install
    ldflags = "-s -w -X main.version=#{version} -X main.commit= -X main.date=#{time.iso8601}}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    output = shell_output("#{bin}/ali --duration=10m --rate=100 http://host.xz 2>&1", 1)
    assert_match "failed to start application: failed to generate terminal interface", output

    assert_match version.to_s, shell_output("#{bin}/ali --version 2>&1")
  end
end
