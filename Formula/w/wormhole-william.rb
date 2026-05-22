class WormholeWilliam < Formula
  desc "End-to-end encrypted file transfer"
  homepage "https://github.com/psanford/wormhole-william"
  url "https://github.com/psanford/wormhole-william/archive/refs/tags/v1.0.8.tar.gz"
  sha256 "42490f3c7e383d7d410e68a83fc18de1a5e9373934a9d71064e10948197759d1"
  license "MIT"
  head "https://github.com/psanford/wormhole-william.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "38501a869f93341426fd494177d0158fbcc92ee75915ec3b6b016d82ae3e3516"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")

    generate_completions_from_executable(bin/"wormhole-william", "shell-completion")
  end

  test do
    # Send "foo" over the wire
    code = "#{rand(1e12)}-test"
    pid = spawn bin/"wormhole-william", "send", "--code", code, "--text", "foo"
    sleep 2
    assert_match "foo\n", shell_output("#{bin}/wormhole-william receive #{code}")
  ensure
    Process.wait(pid)
  end
end
