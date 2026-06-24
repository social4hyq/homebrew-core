class Quien < Formula
  desc "Better WHOIS and domain intelligence toolkit"
  homepage "https://benword.com/quien-a-better-whois-and-domain-intelligence-toolkit"
  url "https://github.com/retlehs/quien/archive/refs/tags/v0.12.0.tar.gz"
  sha256 "49eef2d196a1b9c1e46c037c8fa300f6ced71c952828761fb4810ad8151e14c2"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "61a4ae3ddfc251b2afe48d0c562901e4cc3f9b4854885e7eef1db1f34a74a8a4"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    require "expect"
    require "pty"

    PTY.spawn(bin/"quien", "google.com") do |r, w, pid|
      r.expect "Org *Google LLC"
      w.write "s"
      r.expect "Issuer *Google Trust Services"
    rescue Errno::EIO
      # GNU/Linux raises EIO when read is done on closed pty
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
