class Falcoctl < Formula
  desc "CLI tool for working with Falco and its ecosystem components"
  homepage "https://github.com/falcosecurity/falcoctl"
  url "https://github.com/falcosecurity/falcoctl/archive/refs/tags/v0.14.2.tar.gz"
  sha256 "2ac3bd90913933e7fb6f9a722e1b8999dedaaab158c1ea073405d28c491112c1"
  license "Apache-2.0"
  head "https://github.com/falcosecurity/falcoctl.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e112c2d40edef3f52858b20d61c295eb0cddea8c367d40b13fe5aa9c319dde87"
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
