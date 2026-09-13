class BeadsViewer < Formula
  desc "Terminal-based UI for the Beads issue tracker"
  homepage "https://github.com/Dicklesworthstone/beads_viewer"
  url "https://github.com/Dicklesworthstone/beads_viewer/archive/refs/tags/v0.25.0.tar.gz"
  sha256 "0967ce29a23a0b949862578a3a706ee4a0065f0988e0bc02f08e6e4de1500b85"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3b2ed4d6a1abd9967ec9ebb99d45ae3efc01402df50c058b1e6c2693b108dd55"
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
