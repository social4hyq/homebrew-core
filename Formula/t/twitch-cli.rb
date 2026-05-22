class TwitchCli < Formula
  desc "CLI to make developing on Twitch easier"
  homepage "https://github.com/twitchdev/twitch-cli"
  url "https://github.com/twitchdev/twitch-cli/archive/refs/tags/v1.1.25.tar.gz"
  sha256 "63d13cd54b64e17237650d7aaadb1453fe28565f54111be056beb24d58831c67"
  license "Apache-2.0"
  head "https://github.com/twitchdev/twitch-cli.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ca72d37d78bbe7c6f6ada9bd8fbe8b035a9744d3b8a7e343deeabc90e292ef12"
  end

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "1" if OS.linux? && Hardware::CPU.arm?

    system "go", "build", *std_go_args(ldflags: "-s -w -X main.buildVersion=#{version}", output: bin/"twitch")

    generate_completions_from_executable(bin/"twitch", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/twitch version")
    output = shell_output("#{bin}/twitch mock-api generate 2>&1")
    assert_match "Name: Mock API Client", output
  end
end
