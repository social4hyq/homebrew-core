class Glider < Formula
  desc "Forward proxy with multiple protocols support"
  homepage "https://github.com/nadoo/glider"
  url "https://github.com/nadoo/glider/archive/refs/tags/v0.16.4.tar.gz"
  sha256 "91aa9ad6d56b164b30abedc88a0d371b3af6ff96cfe92f18525fa8e110aaee1d"
  license "GPL-3.0-or-later"
  head "https://github.com/nadoo/glider.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ae1b3717dcf3dba7cdf5d3d13eff28a4d152228680fd49a6044a0b9931b20e53"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.version=#{version}
    ]
    system "go", "build", *std_go_args(ldflags:)

    etc.install buildpath/"config/glider.conf.example" => "glider.conf"
  end

  service do
    run [opt_bin/"glider", "-config", etc/"glider.conf"]
    keep_alive true
  end

  test do
    proxy_port = free_port
    glider = spawn bin/"glider", "-listen", "socks5://:#{proxy_port}"

    begin
      sleep 3
      output = shell_output("curl --socks5 127.0.0.1:#{proxy_port} -L https://brew.sh")
      assert_match "The Missing Package Manager for macOS (or Linux)", output
    ensure
      Process.kill 9, glider
      Process.wait glider
    end
  end
end
