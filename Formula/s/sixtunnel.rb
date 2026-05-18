class Sixtunnel < Formula
  desc "Tunnelling for application that don't speak IPv6"
  homepage "https://github.com/wojtekka/6tunnel"
  url "https://github.com/wojtekka/6tunnel/releases/download/0.14/6tunnel-0.14.tar.gz"
  sha256 "6945312793079408f1ab40071cee68e70158a23560145f1d424a3eb16227f235"
  license "GPL-2.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "14d6d6b9d6b646a24ece0c8bd51e9175f23ef694905b551538f2a03a4daa2e8a"
  end

  head do
    url "https://github.com/wojtekka/6tunnel.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  def install
    system "./autogen.sh" if build.head?
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    require "socket"
    dest_port = free_port
    proxy_port = free_port
    server = TCPServer.new dest_port

    server_pid = fork do
      session = server.accept
      session.puts "Hello world!"
      session.close
    end
    sleep 1

    tunnel_pid = spawn bin/"6tunnel", "-1", "-4", "-d", proxy_port.to_s, "localhost", dest_port.to_s
    sleep 1

    TCPSocket.open("localhost", proxy_port) do |sock|
      assert_equal "Hello world!", sock.gets.chomp
    end
  ensure
    Process.kill "TERM", tunnel_pid if tunnel_pid
    Process.kill "TERM", server_pid if server_pid
  end
end
