class AwsEsProxy < Formula
  desc "Small proxy between HTTP client and AWS Elasticsearch"
  homepage "https://github.com/abutaha/aws-es-proxy"
  url "https://github.com/abutaha/aws-es-proxy/archive/refs/tags/v1.5.tar.gz"
  sha256 "ac6dca6cc271f57831ccf4a413e210d175641932e13dcd12c8d6036e8030e3a5"
  license "Apache-2.0"
  head "https://github.com/abutaha/aws-es-proxy.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e51b13f1209d1e7e4ae137ac968407aa32958a006210f3110203ca1234732d0f"
  end

  depends_on "go" => :build

  # patch to add the missing go.sum file, remove in next release
  patch do
    url "https://github.com/abutaha/aws-es-proxy/commit/5a40bd821e26ce7b6827327f25b22854a07b8880.patch?full_index=1"
    sha256 "b604cf8d51d3d325bd9810feb54f7bb1a1a7a226cada71a08dd93c5a76ffc15f"
  end

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  def caveats
    <<~EOS
      Before you can use these tools you must export some variables to your $SHELL.
        export AWS_ACCESS_KEY="<Your AWS Access ID>"
        export AWS_SECRET_KEY="<Your AWS Secret Key>"
        export AWS_CREDENTIAL_FILE="<Path to the credentials file>"
    EOS
  end

  test do
    address = "127.0.0.1:#{free_port}"
    endpoint = "https://dummy-host.eu-west-1.es.amazonaws.com"

    pid = spawn bin/"aws-es-proxy", "-listen=#{address}", "-endpoint=#{endpoint}"
    begin
      sleep 2
      output = shell_output("curl --silent #{address}")
      assert_match "Failed to sign", output
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
