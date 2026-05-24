class LeafProxy < Formula
  desc "Lightweight and fast proxy utility"
  homepage "https://github.com/eycorsican/leaf"
  url "https://github.com/eycorsican/leaf/archive/refs/tags/v0.14.2.tar.gz"
  sha256 "605bfb0a12b187824a3958066e7e9651a6bfb2f0a889041e73e1d58bb706ed43"
  license "Apache-2.0"
  head "https://github.com/eycorsican/leaf.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "19eb6a3c126eac08c703c7c3ed5c1df8f7ea2a4da64826ff0d300c5f9deaa33e"
  end

  depends_on "rust" => :build

  conflicts_with "leaf", because: "both install a `leaf` binary"
  conflicts_with "leaf-md", because: "both install `leaf` binaries"

  def install
    system "cargo", "install", *std_cargo_args(path: "leaf-cli")
  end

  test do
    (testpath/"config.conf").write <<~EOS
      [General]
      dns-server = 8.8.8.8

      [Proxy]
      SS = ss, 127.0.0.1, #{free_port}, encrypt-method=chacha20-ietf-poly1305, password=123456
    EOS
    output = shell_output "#{bin}/leaf -c #{testpath}/config.conf -t SS"

    assert_match "TCP failed: all attempts failed", output
  end
end
