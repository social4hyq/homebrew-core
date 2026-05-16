class Dexidp < Formula
  desc "OpenID Connect Identity and OAuth 2.0 Provider"
  homepage "https://dexidp.io"
  url "https://github.com/dexidp/dex/archive/refs/tags/v2.45.1.tar.gz"
  sha256 "6dc9bf768d67723d8117268d5177c7450519608f5403cd10e857c89465fa2b9e"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "de93d7bf9b301563c69837c7b85374587af020f3f66568b5462c7f86499ff6a3"
  end

  depends_on "go" => :build

  conflicts_with "dex", because: "both install `dex` binaries"

  def install
    ldflags = "-w -X main.version=#{version}"
    system "go", "build", *std_go_args(ldflags:, output: bin/"dex"), "./cmd/dex"
    pkgetc.install "config.yaml.dist" => "config.yaml"
  end

  service do
    run [opt_bin/"dex", "serve", etc/"dexidp/config.yaml"]
    keep_alive true
    error_log_path var/"log/dex.log"
    log_path var/"log/dex.log"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dex version")

    port = free_port
    cp pkgetc/"config.yaml", testpath
    inreplace "config.yaml", "5556", port.to_s

    pid = spawn bin/"dex", "serve", "config.yaml"
    sleep 3

    assert_match "Dex", shell_output("curl -s localhost:#{port}/dex")
  ensure
    Process.kill "TERM", pid
  end
end
