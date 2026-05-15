class HelmDocs < Formula
  desc "Tool for automatically generating markdown documentation for helm charts"
  homepage "https://github.com/norwoodj/helm-docs"
  url "https://github.com/norwoodj/helm-docs/archive/refs/tags/v1.14.2.tar.gz"
  sha256 "88d1b3401220b2032cd27974264d2dc0da8f9e7b67a8a929a0848505c4e4a0ae"
  license "GPL-3.0-or-later"
  head "https://github.com/norwoodj/helm-docs.git", branch: "master"

  # This repository originally used a date-based version format like `19.0110`
  # (from 2019-01-10) instead of the newer `v1.2.3` format. The regex below
  # avoids tags using the older version format, as they will be treated as
  # newer until version 20.x.
  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d{1,3})(?:\.\d)*)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e4fd2c90a92a81bd5a52e6c58fb1a75f6a8f47c144d6375dd127cbf740e89b44"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}"), "./cmd/helm-docs"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/helm-docs --version")

    (testpath/"Chart.yaml").write <<~YAML
      apiVersion: v2
      name: test-app
      description: A test Helm chart
      version: 0.1.0
      type: application
    YAML

    (testpath/"values.yaml").write <<~YAML
      replicaCount: 1
      image: "nginx:1.19.10"
      service:
        type: ClusterIP
        port: 80
    YAML

    output = shell_output("#{bin}/helm-docs --chart-search-root . 2>&1")
    assert_match "Generating README Documentation for chart .", output
    assert_match "A test Helm chart", (testpath/"README.md").read
  end
end
