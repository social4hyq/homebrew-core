class Grizzly < Formula
  desc "Command-line tool for managing and automating Grafana dashboards"
  homepage "https://grafana.github.io/grizzly/"
  url "https://github.com/grafana/grizzly/archive/refs/tags/v0.7.1.tar.gz"
  sha256 "81811b684ef1bddd3b7147c5095224552a0b35dc3ff210d10e6cbc5e12331160"
  license "Apache-2.0"
  head "https://github.com/grafana/grizzly.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d0d5798478abacc24372b2bc9b6cf75c75722e9ee728e8d29743e2440bf1a952"
  end

  # https://github.com/grafana/grizzly/pull/613
  deprecate! date: "2026-02-17", because: :repo_archived, replacement_formula: "grafanactl"
  disable! date: "2027-02-17", because: :repo_archived, replacement_formula: "grafanactl"

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/grafana/grizzly/pkg/config.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:, output: bin/"grr"), "./cmd/grr"
  end

  test do
    sample_dashboard = testpath/"dashboard_simple.yaml"
    sample_dashboard.write <<~YAML
      apiVersion: grizzly.grafana.com/v1alpha1
      kind: Dashboard
      metadata:
        folder: sample
        name: prod-overview
      spec:
        schemaVersion: 17
        tags:
          - templated
        timezone: browser
        title: Production Overview
        uid: prod-overview
    YAML

    assert_match "prod-overview", shell_output("#{bin}/grr list #{sample_dashboard}")

    assert_match version.to_s, shell_output("#{bin}/grr --version 2>&1")
  end
end
