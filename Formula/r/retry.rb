class Retry < Formula
  desc "Repeat a command until the command succeeds"
  homepage "https://github.com/minfrin/retry"
  url "https://github.com/minfrin/retry/releases/download/retry-1.0.6/retry-1.0.6.tar.bz2"
  sha256 "b5bbdaee16436fabae608fbc58f47df9726b87b945c9eca1524648500b9afdf3"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "daf37ae272f84134856f4283928300ff233812c0375c01afb1cef5fa07a3ec7d"
  end

  def install
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    require "socket"
    port = free_port
    args = %W[--delay 1 --until 0,28 -- curl --max-time 1 telnet://localhost:#{port}]
    Open3.popen2e(bin/"retry", *args) do |_, stdout_and_stderr|
      sleep 3
      assert_match "curl returned 7", stdout_and_stderr.read_nonblock(1024)

      TCPServer.open(port) do |server|
        session = server.accept
        session.puts "Hello world!"
        session.close
      end

      assert_match "Hello world!", stdout_and_stderr.read
    end
  end
end
