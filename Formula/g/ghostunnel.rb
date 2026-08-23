class Ghostunnel < Formula
  desc "Simple SSL/TLS proxy with mutual authentication"
  homepage "https://github.com/ghostunnel/ghostunnel"
  url "https://github.com/ghostunnel/ghostunnel/archive/refs/tags/v1.11.3.tar.gz"
  sha256 "3b7221a474d39cd56598a874d5d9b27b20ebb857c655899b5c6960ccfa3b6a30"
  license "Apache-2.0"
  head "https://github.com/ghostunnel/ghostunnel.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "34d6fe4c9a2131f5799e020839a3d790e6720bc6f5e9541be5ac1379de602cad"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}")

    generate_completions_from_executable(bin/"ghostunnel", shell_parameter_format: "--completion-script-",
                                                           shells:                 [:bash, :zsh])
  end

  test do
    port = free_port
    fork do
      exec bin/"ghostunnel", "client", "--listen=localhost:#{port}", "--target=localhost:4",
        "--disable-authentication", "--shutdown-timeout=1s", "--connect-timeout=1s"
    end
    sleep 1
    sleep 2 if OS.mac? && Hardware::CPU.intel?
    shell_output("curl -o /dev/null http://localhost:#{port}/", 56)
  end
end
