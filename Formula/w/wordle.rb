class Wordle < Formula
  desc "Play wordle in command-line"
  homepage "https://git.hanabi.in/wordle-cli"
  url "https://git.hanabi.in/repos/wordle-cli.git",
      tag:      "v2.0.0",
      revision: "757ede5453457f58b5299fec0b6a0e79fbb27fa9"
  license "AGPL-3.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "17e283f531f476a6c09eaec35d65d11662b1d5179bc075bdc5449112fedb1448"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "src/main.go"
  end

  test do
    require "pty"
    stdout, _stdin, _pid = PTY.spawn(bin/"wordle")
    prompt_first_line = stdout.readline
    striped_line = prompt_first_line.strip
    assert_equal striped_line, "Guess a 5-letter word.  You have 6 tries."
  end
end
