class Regal < Formula
  desc "Linter and language server for Rego"
  homepage "https://www.openpolicyagent.org/projects/regal"
  url "https://github.com/open-policy-agent/regal/archive/refs/tags/v0.42.0.tar.gz"
  sha256 "804a38ed49279dc1e3b36c75d8e63ec0ee1659e3bd04feecd295eb142773f3dc"
  license "Apache-2.0"
  head "https://github.com/open-policy-agent/regal.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "710b4a20ae2ecb38abf3190cf3052c7cb20063809154381ab5780119cdafd721"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/open-policy-agent/regal/pkg/version.Version=#{version}
      -X github.com/open-policy-agent/regal/pkg/version.Commit=#{tap.user}
      -X github.com/open-policy-agent/regal/pkg/version.Timestamp=#{time.iso8601}
      -X github.com/open-policy-agent/regal/pkg/version.Hostname=#{tap.user}
    ]
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"regal", shell_parameter_format: :cobra)
  end

  test do
    (testpath/"test").mkdir

    (testpath/"test/example.rego").write <<~REGO
      package test

      import rego.v1

      default allow := false
    REGO

    output = shell_output("#{bin}/regal lint test/example.rego 2>&1")
    assert_equal "1 file linted. No violations found.", output.chomp

    assert_match version.to_s, shell_output("#{bin}/regal version")
  end
end
