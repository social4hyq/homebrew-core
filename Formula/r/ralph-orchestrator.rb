class RalphOrchestrator < Formula
  desc "Multi-agent orchestration framework for autonomous AI task completion"
  homepage "https://github.com/mikeyobrien/ralph-orchestrator"
  url "https://github.com/mikeyobrien/ralph-orchestrator/archive/refs/tags/v2.10.0.tar.gz"
  sha256 "505de9a909d9b04b9c0ee7576eab83cb8ca878815c662196aa585547caacc0fa"
  license "MIT"
  head "https://github.com/mikeyobrien/ralph-orchestrator.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d185656cc5f0a7db2f51aef39e3bd593f08410cc8d5d5b011984517ffbace18c"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/ralph-cli")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ralph --version")

    system bin/"ralph", "init", "--backend", "claude"
    assert_path_exists testpath/"ralph.yml"
  end
end
