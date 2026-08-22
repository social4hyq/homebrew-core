class Bento < Formula
  desc "Fancy stream processing made operationally mundane"
  homepage "https://warpstreamlabs.github.io/bento/"
  url "https://github.com/warpstreamlabs/bento/archive/refs/tags/v1.21.0.tar.gz"
  sha256 "be2506fa45f64a3c3fe2f3787fab39d704505d0b3b41c8a044c6a936e95034ef"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dcca71772ac9fc4c4257a50a2d8955b32da405a85f10a8c4d38729ee6af8085a"
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
