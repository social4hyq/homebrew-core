class Kamel < Formula
  desc "Apache Camel K CLI"
  homepage "https://camel.apache.org/"
  url "https://www.apache.org/dyn/closer.lua?path=camel/camel-k/2.11.0/camel-k-sources-2.11.0.tar.gz"
  mirror "https://archive.apache.org/dist/camel/camel-k/2.11.0/camel-k-sources-2.11.0.tar.gz"
  sha256 "aace4782b7f4fcb5ff7c49f8c4ead8a5d33b1139678c6f9253c6c37e83d4e78b"
  license "Apache-2.0"
  head "https://github.com/apache/camel-k.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "29365fe43fa495556e1f4d81e34032744af09e03410c6b5c3f96ce2b475de3e2"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/apache/camel-k/v#{version.major}/pkg/util/defaults.GitCommit=#{tap.user}-#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/kamel"
  end

  test do
    run_output = shell_output("#{bin}/kamel 2>&1")
    assert_match "Apache Camel K is a lightweight", run_output

    help_output = shell_output("echo $(#{bin}/kamel help 2>&1)")
    assert_match "kamel [command] --help", help_output.chomp

    get_output = shell_output("echo $(#{bin}/kamel get 2>&1)")
    assert_match "Error: cannot get command client: invalid configuration", get_output

    version_output = shell_output("echo $(#{bin}/kamel version 2>&1)")
    assert_match version.to_s, version_output

    reset_output = shell_output("echo $(#{bin}/kamel reset 2>&1)")
    assert_match "Error: cannot get command client: invalid configuration", reset_output

    rebuild_output = shell_output("echo $(#{bin}/kamel rebuild 2>&1)")
    assert_match "Error: cannot get command client: invalid configuration", rebuild_output

    reset_output = shell_output("echo $(#{bin}/kamel reset 2>&1)")
    assert_match "Error: cannot get command client: invalid configuration", reset_output
  end
end
