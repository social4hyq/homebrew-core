class Quien < Formula
  desc "Better WHOIS and domain intelligence toolkit"
  homepage "https://benword.com/quien-a-better-whois-and-domain-intelligence-toolkit"
  url "https://github.com/retlehs/quien/archive/refs/tags/v0.11.0.tar.gz"
  sha256 "8361a2d292152896e93220ca5e85474ac72b5f44795f640f69b0b2a8dace26c3"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f89b2a468ac18e659a6b664b35e3f26791b6b9e514bd0b67a06b6d2c1c37a66c"
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
