class Burrow < Formula
  desc "Kafka Consumer Lag Checking"
  homepage "https://github.com/linkedin/Burrow"
  url "https://github.com/linkedin/Burrow/archive/refs/tags/v1.9.6.tar.gz"
  sha256 "3dcb0af9ff5741c2d2b3ac39211b9087e1f5dfc7f45ffa18bf9007504d91219f"
  license "Apache-2.0"
  head "https://github.com/linkedin/Burrow.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3838f21794ba44eaa1c556d95ea68f7dac6f83b90f3921f72be43a7c62575965"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args

    inreplace "docker-config/burrow.toml" do |s|
      s.gsub!(/(kafka|zookeeper):/, "localhost:")
      s.sub! "docker-client", "homebrew-client"
    end
    (etc/"burrow").install "docker-config/burrow.toml"
  end

  service do
    run [opt_bin/"burrow", "--config-dir", etc/"burrow"]
    keep_alive true
    error_log_path var/"log/burrow.log"
    log_path var/"log/burrow.log"
    working_dir var
  end

  test do
    port = free_port
    (testpath/"burrow.toml").write <<~TOML
      [httpserver.default]
      address="localhost:#{port}"
    TOML
    spawn bin/"burrow"
    sleep 1

    output = shell_output("curl -s localhost:#{port}/v3/kafka")
    assert_match "cluster list returned", output
  end
end
