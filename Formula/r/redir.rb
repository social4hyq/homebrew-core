class Redir < Formula
  desc "TCP port redirector for UNIX"
  homepage "https://github.com/troglobit/redir"
  url "https://github.com/troglobit/redir/releases/download/v3.3/redir-3.3.tar.xz"
  sha256 "7ce53ac52a24c1b3279b994bfffbd429c44df2db10a4b1a0f54e108604fdae6e"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c1ab7c959a25f039005299ece2bc0b13ba044dde69479c049cef237c0ca71fc6"
  end

  def install
    system "./configure", "--disable-silent-rules", "--enable-compat", *std_configure_args
    system "make", "install"
  end

  test do
    cport = free_port
    lport = free_port
    redir_pid = spawn bin/"redir", "--cport=#{cport}", "--lport=#{lport}"
    Process.detach(redir_pid)

    server = TCPServer.new(cport)
    server_pid = fork do
      session = server.accept
      session.puts "Hello world!"
      session.close
    end

    # Give time to processes start
    sleep(1)

    begin
      # Check if the process is running
      system "kill", "-0", redir_pid

      # Check if the port redirect works
      TCPSocket.open("localhost", lport) do |sock|
        assert_equal "Hello world!", sock.gets.chomp
      end
    ensure
      Process.kill("TERM", redir_pid)
      Process.kill("TERM", server_pid)
      Process.wait(server_pid)
    end
  end
end
