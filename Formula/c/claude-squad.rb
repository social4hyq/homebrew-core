class ClaudeSquad < Formula
  desc "Manage multiple AI agents like Claude Code, Aider and Codex in your terminal"
  homepage "https://smtg-ai.github.io/claude-squad/"
  url "https://github.com/smtg-ai/claude-squad/archive/refs/tags/v1.0.18.tar.gz"
  sha256 "3ef6ead7fb78fe73fc0a4f2d12d49c5c3224ea0fa9116681a21bd4bf63a58f57"
  license "AGPL-3.0-only"
  head "https://github.com/smtg-ai/claude-squad.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "adfed674968a8ff19653ba7b0c24ec51dcc2fe4eef1a2ea99636011e5f061248"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
    generate_completions_from_executable(bin/"claude-squad", shell_parameter_format: :cobra)
  end

  test do
    output = shell_output(bin/"claude-squad")
    assert_includes output, "claude-squad must be run from within a git repository"
  end
end
