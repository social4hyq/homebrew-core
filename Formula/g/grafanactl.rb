class Grafanactl < Formula
  desc "CLI to interact with Grafana"
  homepage "https://grafana.github.io/grafanactl/"
  url "https://github.com/grafana/grafanactl/archive/refs/tags/v0.1.10.tar.gz"
  sha256 "c3a3fef02f073aa92fb7b62c6f60a26e80fe794cf158f86830fe38ff053035fd"
  license "Apache-2.0"
  head "https://github.com/grafana/grafanactl.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2a0236b660f2d45a3d0b71fed30f2d96420be66137f02f2bf8027709ee6e90bc"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version} -X main.commit=#{tap.user} -X main.date=#{time.iso8601}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/grafanactl"

    generate_completions_from_executable(bin/"grafanactl", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/grafanactl --version").strip
    assert_match "current-context: default", shell_output("#{bin}/grafanactl config view")
  end
end
