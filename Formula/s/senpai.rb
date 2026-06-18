class Senpai < Formula
  desc "Modern terminal IRC client"
  homepage "https://sr.ht/~delthas/senpai/"
  url "https://git.sr.ht/~delthas/senpai/archive/v0.4.1.tar.gz"
  sha256 "ab786b7b3cffce69d080c3b58061e14792d9065ba8831f745838c850acfeab24"
  license "MIT"
  head "https://git.sr.ht/~delthas/senpai", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "18d7eda2ed12538bf25bce4420bedc6b5683c6e6663d52a9d54599ce15d8b31b"
  end

  depends_on "go" => :build
  depends_on "scdoc" => :build

  def install
    system "make"
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    require "pty"

    stdout, _stdin, _pid = PTY.spawn bin/"senpai"
    _ = stdout.readline
    assert_equal "Configuration assistant: senpai will create a configuration file for you.\r\n", stdout.readline
  end
end
