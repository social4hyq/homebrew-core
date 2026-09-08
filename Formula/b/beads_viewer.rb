class BeadsViewer < Formula
  desc "Terminal-based UI for the Beads issue tracker"
  homepage "https://github.com/Dicklesworthstone/beads_viewer"
  url "https://github.com/Dicklesworthstone/beads_viewer/archive/refs/tags/v0.24.1.tar.gz"
  sha256 "b09713a0b58c5b1be7af1c8402db9855156f7b20594a9150333df9ae97fc0c4e"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "62778ac32af66de7644aeb05bc46ca875a5e22d4d22fdc882e50e07fec2b9030"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[-X github.com/Dicklesworthstone/beads_viewer/pkg/version.version=v#{version}]
    system "go", "build", *std_go_args(ldflags:, output: bin/"bv"), "./cmd/bv"
  end

  test do
    assert_match "v#{version}", shell_output("#{bin}/bv --version")

    # Test that it detects missing .beads directory.
    output = shell_output("#{bin}/bv --robot-insights 2>&1", 1)
    assert_match "failed to read beads directory", output
  end
end
