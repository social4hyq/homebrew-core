class Snowflake < Formula
  desc "Pluggable Transport using WebRTC, inspired by Flashproxy"
  homepage "https://www.torproject.org"
  url "https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/snowflake/-/archive/v2.13.1/snowflake-v2.13.1.tar.gz"
  sha256 "3102c0782422205f6cea7609ab67cb5fd080e048880712ebe0c85540138cc09f"
  license "BSD-3-Clause"
  head "https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/snowflake.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d03b56cd1ae929d4fa40fdaa07d93f251bb16078b70d2d13eb573f3fb1aca602"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w"
    system "go", "build", *std_go_args(ldflags:, output: bin/"snowflake-broker"), "./broker"
    system "go", "build", *std_go_args(ldflags:, output: bin/"snowflake-client"), "./client"
    system "go", "build", *std_go_args(ldflags:, output: bin/"snowflake-proxy"), "./proxy"
    system "go", "build", *std_go_args(ldflags:, output: bin/"snowflake-server"), "./server"

    man1.install "doc/snowflake-client.1"
    man1.install "doc/snowflake-proxy.1"
  end

  test do
    assert_match "open /usr/share/tor/geoip: no such file", shell_output("#{bin}/snowflake-broker 2>&1", 1)
    assert_match "ENV-ERROR no TOR_PT_MANAGED_TRANSPORT_VER", shell_output("#{bin}/snowflake-client 2>&1", 1)
    assert_match "the --acme-hostnames option is required", shell_output("#{bin}/snowflake-server 2>&1", 1)
  end
end
