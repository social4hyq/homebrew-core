class Wthrr < Formula
  desc "Weather Companion for the Terminal"
  homepage "https://github.com/ttytm/wthrr-the-weathercrab"
  url "https://github.com/ttytm/wthrr-the-weathercrab/archive/refs/tags/v1.2.1.tar.gz"
  sha256 "ff5b47f2046ebefa9ff28cb52ece49a06f7b89230578801c338c77802aa721e0"
  license "MIT"
  head "https://github.com/ttytm/wthrr-the-weathercrab.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2d902270d41bcdc4bf4e41bf044fab66c302104484a198f1e3891e72270c8dce"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3"
  end

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/wthrr --version")
    system bin/"wthrr", "-h"

    require "pty"

    PTY.spawn(bin/"wthrr", "-l", "en_US", "Kyoto") do |r, _w, pid|
      output = r.gets
      assert_match "Hey friend. I'm glad you are asking.", output
    ensure
      Process.kill("TERM", pid)
    end
  end
end
