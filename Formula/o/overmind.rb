class Overmind < Formula
  desc "Process manager for Procfile-based applications and tmux"
  homepage "https://github.com/DarthSim/overmind"
  url "https://github.com/DarthSim/overmind/archive/refs/tags/v2.5.1.tar.gz"
  sha256 "d616b89465d488878ed2e1f79e66f8af5b5c2f1d3cf75c2b08e04fb04752d187"
  license "MIT"
  head "https://github.com/DarthSim/overmind.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c8b86f8772069bff581b26c5e8b0616956aef22835c1b6423b052b5087f4ab3b"
  end

  depends_on "go" => :build
  depends_on "tmux"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    expected_message = "overmind: open ./Procfile: no such file or directory"
    assert_match expected_message, shell_output("#{bin}/overmind start 2>&1", 1)
    (testpath/"Procfile").write("test: echo 'test message'; sleep 1")
    expected_message = "test message"
    assert_match expected_message, shell_output("#{bin}/overmind start")
  end
end
