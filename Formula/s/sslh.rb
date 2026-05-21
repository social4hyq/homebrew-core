class Sslh < Formula
  desc "Forward connections based on first data packet sent by client"
  homepage "https://www.rutschle.net/tech/sslh.shtml"
  url "https://www.rutschle.net/tech/sslh/sslh-v2.3.1.tar.gz"
  sha256 "51a5516ec5cb01823633b4d8cacdeee4efa0c56ef620d1c996d4f52ca51a601b"
  license all_of: ["GPL-2.0-or-later", "BSD-2-Clause"]
  head "https://github.com/yrutschle/sslh.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4a1807520bc79304c5c97e315bda6d2e14e582a0d7c03b852ed1e66f81936ef9"
  end

  depends_on "libconfig"
  depends_on "libev"
  depends_on "pcre2"

  def install
    system "./configure", *std_configure_args
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    listen_port = free_port
    target_port = free_port
    pid = spawn sbin/"sslh", "--http=localhost:#{target_port}", "--listen=localhost:#{listen_port}", "--foreground"

    fork do
      TCPServer.open(target_port) do |server|
        session = server.accept
        session.write "HTTP/1.1 200 OK\r\n\r\nHello world!"
        session.close
      end
    end

    sleep 1
    sleep 5 if OS.mac? && Hardware::CPU.intel?
    assert_equal "Hello world!", shell_output("curl -s http://localhost:#{listen_port}")
  ensure
    Process.kill "TERM", pid
    Process.wait pid
  end
end
