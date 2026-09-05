class Epinio < Formula
  desc "CLI for Epinio, the Application Development Engine for Kubernetes"
  homepage "https://epinio.io/"
  url "https://github.com/epinio/epinio/archive/refs/tags/v1.14.2.tar.gz"
  sha256 "4f290987fe290c4a23f29b1c14b2f7bb703264ae173e1aade0f6550aead06774"
  license "Apache-2.0"

  # Upstream creates a stable version tag ahead of release but a version isn't
  # considered released until they create the GitHub release.
  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :github_releases
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "25116c5a100ea7bf54d2959749d1f29022cd051285f22e77b52f94bcc9cec0e4"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X github.com/epinio/epinio/internal/version.Version=v#{version}")

    generate_completions_from_executable(bin/"epinio", shell_parameter_format: :cobra)
  end

  test do
    output = shell_output("#{bin}/epinio version 2>&1")
    assert_match "Epinio Version: v#{version}", output

    output = shell_output("#{bin}/epinio settings show 2>&1")
    assert_match "Show Settings", output
  end
end
