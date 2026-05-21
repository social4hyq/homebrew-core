class Ehco < Formula
  desc "Network relay tool and a typo :)"
  homepage "https://github.com/Ehco1996/ehco"
  url "https://github.com/Ehco1996/ehco/archive/refs/tags/v1.1.6.tar.gz"
  sha256 "002d18a6b631f5026b2dc90dbbe55dc46469fbaaef24ad812a281356d54ebe26"
  license "GPL-3.0-only"
  head "https://github.com/Ehco1996/ehco.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "57eb09adb2f8255826a15a35abf0bdf5390abb2b2a90d8e31f5a681ce8ea437a"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/Ehco1996/ehco/internal/constant.GitBranch=master
      -X github.com/Ehco1996/ehco/internal/constant.GitRevision=#{tap.user}
      -X github.com/Ehco1996/ehco/internal/constant.BuildTime=#{time.iso8601}
    ]
    # -tags added here are via upstream's Makefile/CI builds
    tags = "nofibrechannel,nomountstats"

    system "go", "build", *std_go_args(ldflags:, tags:), "cmd/ehco/main.go"
  end

  test do
    version_info = shell_output("#{bin}/ehco -v 2>&1")
    assert_match "Version=#{version}", version_info

    # run tcp server
    server_port = free_port
    server = TCPServer.new(server_port)
    server_pid = fork do
      session = server.accept
      session.puts "Hello world!"
      session.close
    end
    sleep 1

    # run ehco server
    listen_port = free_port
    ehco_pid = spawn bin/"ehco", "-l", "localhost:#{listen_port}", "-r", "localhost:#{server_port}"
    sleep 1

    TCPSocket.open("localhost", listen_port) do |sock|
      assert_match "Hello world!", sock.gets
    end
  ensure
    Process.kill "TERM", ehco_pid if ehco_pid
    Process.kill "TERM", server_pid if server_pid
  end
end
