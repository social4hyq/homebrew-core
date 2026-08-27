class Ctlptl < Formula
  desc "Making local Kubernetes clusters fun and easy to set up"
  homepage "https://github.com/tilt-dev/ctlptl"
  url "https://github.com/tilt-dev/ctlptl/archive/refs/tags/v0.9.5.tar.gz"
  sha256 "ffcdbaa22f4590167fffaba6c7a177e108e719e614e306a58f1393e227f85e3f"
  license "Apache-2.0"
  head "https://github.com/tilt-dev/ctlptl.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "50cdd26452c54323f90793d1e2b8333da7816668ad3b763a6d5c8af1ba994ead"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.version=#{version}
      -X main.date=#{time.iso8601}
    ]
    system "go", "build", *std_go_args(ldflags:), "./cmd/ctlptl"

    generate_completions_from_executable(bin/"ctlptl", shell_parameter_format: :cobra)
  end

  test do
    assert_match "v#{version}", shell_output("#{bin}/ctlptl version")
    assert_empty shell_output("#{bin}/ctlptl get")
    assert_match "not found", shell_output("#{bin}/ctlptl delete cluster nonexistent 2>&1", 1)
  end
end
