class IcebergCli < Formula
  desc "Command-line interface for Apache Iceberg"
  homepage "https://go.iceberg.apache.org/cli.html"
  url "https://github.com/apache/iceberg-go/archive/refs/tags/v0.6.0.tar.gz"
  sha256 "3ecdaa8851b84fa1c109be61b7ae6817aef6f301cee98ce68eac1eb649686050"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1620ad21eb841ef5f9e2e93e68b97c820db9394c516450911274e5af43bdf703"
  end

  depends_on "go" => :build

  def install
    # See: https://github.com/apache/iceberg-go/pull/531
    inreplace "utils.go", "(unknown version)", version.to_s

    system "go", "build", *std_go_args(output: bin/"iceberg"), "./cmd/iceberg"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/iceberg --version")
    output = shell_output("#{bin}/iceberg list 2>&1", 1)
    assert_match "unsupported protocol scheme", output
  end
end
