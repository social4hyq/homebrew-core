class Somo < Formula
  desc "Human-friendly alternative to netstat for socket and port monitoring"
  homepage "https://github.com/theopfr/somo"
  url "https://github.com/theopfr/somo/archive/refs/tags/v1.3.3.tar.gz"
  sha256 "011ff1fe6e4e973c59526fd5c50d2cdd040d1517f26a321e21807b658047377a"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5c3d2932acbe864a51a5bf666609be3c7ddfafb14d2ff0466812e7b1e1bda9dd"
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
