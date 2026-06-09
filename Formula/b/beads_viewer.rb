class BeadsViewer < Formula
  desc "Terminal-based UI for the Beads issue tracker"
  homepage "https://github.com/Dicklesworthstone/beads_viewer"
  url "https://github.com/Dicklesworthstone/beads_viewer/archive/refs/tags/v0.17.0.tar.gz"
  sha256 "26aefd48cfe44cadeba22b032a276a6b62748fc114281709110d0b0b27630654"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ca8763a25c2e3ec8fd7c830e3af2cf84452fdfff7cf73d6207f29595654b3a3a"
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
