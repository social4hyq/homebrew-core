class Tctl < Formula
  desc "Temporal CLI (tctl)"
  homepage "https://docs.temporal.io/cli"
  url "https://github.com/temporalio/tctl/archive/refs/tags/v1.18.1.tar.gz"
  sha256 "945272db4860e3a015e43b4ffc8fc24ecd585e604f4b94b3a964d2f4e51b9c32"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7128e18e6abdcfa680889ff8ec1a5b2ede4847d1ec03c6e498d1680b0066b99e"
  end

  deprecate! date: "2024-12-04", because: :unmaintained, replacement_formula: "temporal"
  disable! date: "2025-12-04", because: :unmaintained, replacement_formula: "temporal"

  depends_on "go" => :build

  conflicts_with "teleport", because: "both install `tctl` binaries"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/tctl/main.go"
    system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/"tctl-authorization-plugin"),
      "./cmd/plugins/tctl-authorization-plugin"
  end

  test do
    # Given tctl is pointless without a server, not much interesting to test here.
    run_output = shell_output("#{bin}/tctl --version 2>&1")
    assert_match "tctl version", run_output

    run_output = shell_output("#{bin}/tctl --ad 192.0.2.0:1234 n l 2>&1", 1)
    assert_match "rpc error", run_output
  end
end
