class Countdown < Formula
  desc "Terminal countdown timer"
  homepage "https://github.com/antonmedv/countdown"
  url "https://github.com/antonmedv/countdown/archive/refs/tags/v1.5.0.tar.gz"
  sha256 "ac83ec593674a367913413796e8708680cbb6504c8f68ce17152d800a92ccf3b"
  license "MIT"
  head "https://github.com/antonmedv/countdown.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "22e38d5cebce386c971f119eef1dff97ee7473be0ec2a64d9844bff460429e4a"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    pipe_output bin/"countdown", "0m0s"
  end
end
