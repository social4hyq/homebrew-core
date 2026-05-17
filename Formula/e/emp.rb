class Emp < Formula
  desc "CLI for Empire"
  homepage "https://github.com/remind101/empire"
  url "https://github.com/remind101/empire/archive/refs/tags/v0.13.0.tar.gz"
  sha256 "1294de5b02eaec211549199c5595ab0dbbcfdeb99f670b66e7890c8ba11db22b"
  license "BSD-2-Clause"
  head "https://github.com/remind101/empire.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4b676a2304f66f918cdba8051a10d79a591a5354a030c23f97e5bb62cfbcf2ee"
  end

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath
    ENV["GO111MODULE"] = "auto"

    (buildpath/"src/github.com/remind101/").mkpath
    ln_s buildpath, buildpath/"src/github.com/remind101/empire"

    system "go", "build", *std_go_args, "./src/github.com/remind101/empire/cmd/emp"
  end

  test do
    port = free_port

    # Mock an API server response to test the CLI
    fork do
      server = TCPServer.new(port)
      resp = {
        "created_at"  => "2015-10-12T0:00:00.00000000-00:00",
        "description" => "my awesome release",
        "id"          => "v1",
        "user"        => {
          "id"    => "zab",
          "email" => "zab@waba.com",
        },
        "version"     => 1,
      }
      body = JSON.generate([resp])

      loop do
        socket = server.accept
        socket.write "HTTP/1.1 200 OK\r\n" \
                     "Content-Type: application/json; charset=utf-8\r\n" \
                     "Content-Length: #{body.bytesize}\r\n" \
                     "\r\n"
        socket.write body
        socket.close
      end
    end

    sleep 1

    ENV["EMPIRE_API_URL"] = "http://127.0.0.1:#{port}"
    assert_match(/v1  zab  Oct 1(1|2|3)  2015  my awesome release/,
      shell_output("#{bin}/emp releases -a foo").strip)
  end
end
