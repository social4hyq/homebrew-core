class SlothCli < Formula
  desc "Prometheus SLO generator"
  homepage "https://sloth.dev/"
  url "https://github.com/slok/sloth/archive/refs/tags/v0.16.0.tar.gz"
  sha256 "f1ddad49462cf66652e611f7903ecb0dd86b9fa8f4bc43c7e458e8fa87de854c"
  license "Apache-2.0"
  head "https://github.com/slok/sloth.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f3d173c1bf30f3abc48d12f52a4badc58e5953e02a3433992e26e887044c4767"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/slok/sloth/internal/info.Version=#{version}"
    system "go", "build", *std_go_args(output: bin/"sloth", ldflags:), "./cmd/sloth"

    pkgshare.install "examples"
  end

  test do
    test_file = pkgshare/"examples/getting-started.yml"

    output = shell_output("#{bin}/sloth validate -i #{test_file} 2>&1")
    assert_match "Validation succeeded", output

    output = shell_output("#{bin}/sloth generate -i #{test_file} 2>&1")
    assert_match "Plugins loaded", output

    assert_match version.to_s, shell_output("#{bin}/sloth version")
  end
end
