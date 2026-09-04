class CqlProxy < Formula
  desc "DataStax cql-proxy enables Cassandra apps to use Astra DB without code changes"
  homepage "https://github.com/datastax/cql-proxy"
  url "https://github.com/datastax/cql-proxy/archive/refs/tags/v0.2.1.tar.gz"
  sha256 "41a6d8a65446f2cb65b004de561adccae58a2066119c21e0fb24bf3999dd58c2"
  license "Apache-2.0"
  head "https://github.com/datastax/cql-proxy.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1c94a541fdf2ae641c28db5e9436e1873524559e8ec410d877f28c845310ffd3"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    touch "secure.txt"
    output = shell_output("#{bin}/cql-proxy -b secure.txt --bind 127.0.0.1 2>&1", 2)
    assert_match "unable to open", output
  end
end
