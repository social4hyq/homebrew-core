class Tmuxai < Formula
  desc "AI-powered, non-intrusive terminal assistant"
  homepage "https://tmuxai.dev/"
  url "https://github.com/BoringDystopiaDevelopment/tmuxai/archive/refs/tags/v2.3.0.tar.gz"
  sha256 "40e2027a162003f10b6f428449b33a09855c8181b989283f59b8645b7808f385"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "53eb19caa2f3594c0c0e17fe3081156b3e388e0496e8fda41611d27d62670732"
  end

  depends_on "go" => :build
  depends_on "tmux"

  def install
    ldflags = "-s -w -X github.com/alvinunreal/tmuxai/internal.Version=v#{version}"

    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tmuxai -v")

    output = shell_output("#{bin}/tmuxai -f nonexistent 2>&1", 1)
    assert_match "Error reading task file", output
  end
end
