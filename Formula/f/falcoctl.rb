class Falcoctl < Formula
  desc "CLI tool for working with Falco and its ecosystem components"
  homepage "https://github.com/falcosecurity/falcoctl"
  url "https://github.com/falcosecurity/falcoctl/archive/refs/tags/v0.14.1.tar.gz"
  sha256 "49a0e64c05444be12ec75507c069292d26c9057ed5353ea5d10f1e9b7d7ce0df"
  license "Apache-2.0"
  head "https://github.com/falcosecurity/falcoctl.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "116b9d4c9b5ba5706318d8c5f9e034aaff6581f19282b8e32f3929653d1a15ad"
  end

  depends_on "go" => :build

  def install
    pkg = "github.com/falcosecurity/falcoctl/cmd/version"
    ldflags = %W[
      -s -w
      -X #{pkg}.buildDate=#{time.iso8601}
      -X #{pkg}.gitCommit=#{tap.user}
      -X #{pkg}.semVersion=#{version}
    ]

    system "go", "build", *std_go_args(ldflags:), "."

    generate_completions_from_executable(bin/"falcoctl", shell_parameter_format: :cobra)
  end

  test do
    (testpath/"index.yaml").write <<~YAML
      - name: test-artifact
        type: rulesfile
        registry: ghcr.io
        repository: falcosecurity/rules/falco-rules
    YAML

    config = testpath/"falcoctl.yaml"
    system bin/"falcoctl", "index", "add", "myindex", "file://#{testpath}/index.yaml", "--config", config
    assert_match "myindex", shell_output("#{bin}/falcoctl index list --config #{config}")

    assert_match version.to_s, shell_output("#{bin}/falcoctl version")
  end
end
