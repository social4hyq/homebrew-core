class Tinyice < Formula
  desc "Modern, all-in-one Icecast-compatible audio/video streaming server"
  homepage "https://github.com/DatanoiseTV/tinyice"
  url "https://github.com/DatanoiseTV/tinyice/archive/refs/tags/v2.10.2.tar.gz"
  sha256 "d3816726c366f0fbbe68a9a507d1a1053fbdecb8f4d0a1294335e63381692854"
  license "Apache-2.0"
  head "https://github.com/DatanoiseTV/tinyice.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "eee63cf632f4b97f4d6743266a9e68a666c72dbea1aa4ded83422c6442bb5819"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.Version=#{version}
      -X main.Commit=#{tap.user}
    ]
    system "go", "build", *std_go_args(ldflags:)
  end

  service do
    run [opt_bin/"tinyice"]
    keep_alive true
    working_dir var/"tinyice"
    log_path var/"log/tinyice.log"
    error_log_path var/"log/tinyice.log"
  end

  test do
    port = free_port

    # Write minimal config
    (testpath/"tinyice.json").write <<~JSON
      {
        "bind_host": "127.0.0.1",
        "port": "#{port}",
        "admin_user": "admin",
        "admin_password": "test"
      }
    JSON

    pid = spawn bin/"tinyice", chdir: testpath
    sleep 3

    begin
      output = shell_output("curl -s --fail http://127.0.0.1:#{port}/")
      assert_match("TinyIce", output)
    ensure
      Process.kill "TERM", pid
      Process.wait pid
    end
  end
end
