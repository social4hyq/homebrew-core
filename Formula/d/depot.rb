class Depot < Formula
  desc "Build your Docker images in the cloud"
  homepage "https://depot.dev/"
  url "https://github.com/depot/cli/archive/refs/tags/v2.102.7.tar.gz"
  sha256 "9697ebe4cb50d7e25528ec54ea212a32a7a1da734fdb48a77c7c3a7ec92f3559"
  license "MIT"
  head "https://github.com/depot/cli.git", branch: "main"

  # Upstream sometimes creates a tag with a stable version format but does not
  # create a release on GitHub.
  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "886ac6b49e64ca213c6a40a0cf1eaba0885bb57e24fc8195e45f9af90f4e5bd7"
  end

  depends_on "go" => :build

  # Fix linking on Linux arm64 with Go 1.27, which rejects cpuid 2.0.4's linkname to `runtime.sched_getaffinity`.
  patch do
    url "https://github.com/depot/cli/commit/627f8a6dfad7e7f2f33c774d3aa22af9884f0ebb.patch?full_index=1"
    sha256 "bffa3eaea34bebeeb3c27fb9ed326137b8824a1ded170eeeb2cdd91c30dd48ac"
    type :unofficial
    resolves "https://github.com/depot/cli/pull/570"
  end

  def install
    ldflags = %W[
      -X github.com/depot/cli/internal/build.Version=#{version}
      -X github.com/depot/cli/internal/build.Date=#{time.iso8601}
      -X github.com/depot/cli/internal/build.SentryEnvironment=release
    ]

    system "go", "build", *std_go_args(ldflags:), "./cmd/depot"

    generate_completions_from_executable(bin/"depot", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/depot --version")
    output = shell_output("#{bin}/depot list builds 2>&1", 1)
    assert_match "unknown project ID", output
  end
end
