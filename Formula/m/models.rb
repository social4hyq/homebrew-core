class Models < Formula
  desc "Fast TUI and CLI for browsing AI models, benchmarks, and coding agents"
  homepage "https://github.com/arimxyer/models"
  url "https://github.com/arimxyer/models/archive/refs/tags/v0.13.0.tar.gz"
  sha256 "b747f3669a41926af9cdeb74e2d8e8f65d18479598c582ac5b6c541101355a60"
  license "MIT"
  head "https://github.com/arimxyer/models.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "656a650a035dad2d7ab01e6df4bbcee5dc9cc5f9c398de3c23a6db4119e0e41c"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/models --version")
    assert_match "claude-code", shell_output("#{bin}/models agents list-sources")
  end
end
