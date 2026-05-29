class Slacknimate < Formula
  desc "Text animation for Slack messages"
  homepage "https://github.com/mroth/slacknimate"
  url "https://github.com/mroth/slacknimate/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "71c7a65192c8bbb790201787fabbb757de87f8412e0d41fe386c6b4343cb845c"
  license "MPL-2.0"
  head "https://github.com/mroth/slacknimate.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c86c1c14aff8990c7f182a453622b5a826dadb2bb164454e485e06da2817a2e6"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/slacknimate"
  end

  test do
    system bin/"slacknimate", "--version"
    system bin/"slacknimate", "--help"
  end
end
