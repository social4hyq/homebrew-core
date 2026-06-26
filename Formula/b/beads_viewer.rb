class BeadsViewer < Formula
  desc "Terminal-based UI for the Beads issue tracker"
  homepage "https://github.com/Dicklesworthstone/beads_viewer"
  url "https://github.com/Dicklesworthstone/beads_viewer/archive/refs/tags/v0.17.1.tar.gz"
  sha256 "67fe4faeb1ea7b366d80b49f28cf2541429bd6e29bd4a7023630fa309a70414a"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b52a737433b7fb9f80cf881aee087fc66f4c6453d5e086837c37a270cda96742"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/Dicklesworthstone/beads_viewer/pkg/version.Version=v#{version}
    ]
    system "go", "build", *std_go_args(ldflags:, output: bin/"bv"), "./cmd/bv"
  end

  test do
    assert_match "v#{version}", shell_output("#{bin}/bv --version")

    # Test that it detects missing .beads directory.
    output = shell_output("#{bin}/bv --robot-insights 2>&1", 1)
    assert_match "failed to read beads directory", output
  end
end
