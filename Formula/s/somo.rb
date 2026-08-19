class Somo < Formula
  desc "Human-friendly alternative to netstat for socket and port monitoring"
  homepage "https://github.com/theopfr/somo"
  url "https://github.com/theopfr/somo/archive/refs/tags/v1.3.4.tar.gz"
  sha256 "3181a1bdc990bd26d7efe3e546d411cc9464203ca85b683e0b3647ba893cf7ab"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "18fa5ba0fe944a2ae4abed450f19ed8ce36218aac3637ddf282aff1da366d5c7"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    generate_completions_from_executable(bin/"somo", "generate-completions")
  end

  test do
    port = free_port
    TCPServer.open("localhost", port) do |_server|
      output = JSON.parse(shell_output("#{bin}/somo --json --port #{port}"))
      assert_equal port.to_s, output.first["local_port"]
    end
  end
end
