class Slackcat < Formula
  desc "Command-line utility for posting snippets to Slack"
  homepage "https://github.com/bcicen/slackcat"
  url "https://github.com/bcicen/slackcat/archive/refs/tags/1.7.3.tar.gz"
  sha256 "2e3ed7ad5ab3075a8e80a6a0b08a8c52bb8e6e39f6ab03597f456278bfa7768b"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2db6d22212da92c9f83382ca9caa6d9b2ef95dd2628ba48aaa89349d49286e92"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/slackcat -v")
  end
end
