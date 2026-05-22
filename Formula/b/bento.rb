class Bento < Formula
  desc "Fancy stream processing made operationally mundane"
  homepage "https://warpstreamlabs.github.io/bento/"
  url "https://github.com/warpstreamlabs/bento/archive/refs/tags/v1.17.0.tar.gz"
  sha256 "890b066f9f0e28501c499cdc9b6398177e4d2dee135ce19d8f449485eec40a5e"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e3c6072c74cc6acb5fb12cf995259483ffed689113679e217ba593c85511d5ba"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w  -X github.com/warpstreamlabs/bento/internal/cli.Version=#{version} -X main.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/bento"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/bento --version")

    (testpath/"config.yaml").write <<~YAML
      input:
        stdin: {}#{" "}

      pipeline:
        processors:
          - mapping: root = content().uppercase()

      output:
        stdout: {}
    YAML

    output = shell_output("echo foobar | bento -c #{testpath}/config.yaml")
    assert_match "FOOBAR", output
  end
end
