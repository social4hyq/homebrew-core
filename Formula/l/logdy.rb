class Logdy < Formula
  desc "Web based real-time log viewer"
  homepage "https://logdy.dev"
  url "https://github.com/logdyhq/logdy-core/archive/refs/tags/v0.17.1.tar.gz"
  sha256 "bd5db124e736e42d3671697787a26b354e0be6e787a95e69c054ad873058fcec"
  license "Apache-2.0"
  head "https://github.com/logdyhq/logdy-core.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0703130e42ef700009ca0f87f093a10f77e907b8e30b3bc43f7b402180f9d6f3"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"logdy", shell_parameter_format: :cobra)
  end

  test do
    port = free_port
    r, _, pid = PTY.spawn("#{bin}/logdy stdin --port=#{port}")
    assert_match "Listen to stdin (from pipe)", r.readline
  ensure
    Process.kill("TERM", pid)
  end
end
