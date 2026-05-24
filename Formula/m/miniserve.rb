class Miniserve < Formula
  desc "High performance static file server"
  homepage "https://github.com/svenstaro/miniserve"
  url "https://github.com/svenstaro/miniserve/archive/refs/tags/v0.35.0.tar.gz"
  sha256 "8ae108c161f2ed740f8c4b4dfd0a80805adcbaf7a05a6128f2b4d8f5093f5490"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "830cebaf472ce3e036ed5d49361d663411664220f2e06700dce7360b4a0cd889"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"miniserve", "--print-completions")
    (man1/"miniserve.1").write Utils.safe_popen_read(bin/"miniserve", "--print-manpage")
  end

  test do
    port = free_port
    pid = spawn bin/"miniserve", bin/"miniserve", "-i", "127.0.0.1", "--port", port.to_s

    begin
      sleep 2
      read = (bin/"miniserve").read
      assert_equal read, shell_output("curl localhost:#{port}")
    ensure
      Process.kill("SIGINT", pid)
      Process.wait(pid)
    end
  end
end
