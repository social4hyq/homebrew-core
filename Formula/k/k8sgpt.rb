class K8sgpt < Formula
  desc "Scanning your k8s clusters, diagnosing, and triaging issues in simple English"
  homepage "https://k8sgpt.ai/"
  url "https://github.com/k8sgpt-ai/k8sgpt/archive/refs/tags/v0.4.36.tar.gz"
  sha256 "81b9fc2cb52ba44a3b80fe5d69cfcd43dd389ac29d5e2d46c14f9cfa6e2f87c2"
  license "Apache-2.0"
  head "https://github.com/k8sgpt-ai/k8sgpt.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b8c0b5d0cc77d4cf643d3bec422e66640068c7b727300a7328cf380ea0d50abe"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version} -X main.commit=#{tap.user} -X main.date=#{time.iso8601}"
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"k8sgpt", shell_parameter_format: :cobra)
  end

  test do
    output = shell_output("#{bin}/k8sgpt analyze --explain --filter=Service", 1)
    assert_match "try setting KUBERNETES_MASTER environment variable", output

    assert_match version.to_s, shell_output("#{bin}/k8sgpt version")
  end
end
