class Istioctl < Formula
  desc "Istio configuration command-line utility"
  homepage "https://istio.io/"
  url "https://github.com/istio/istio/archive/refs/tags/1.31.0.tar.gz"
  sha256 "92c1b606ee9c7ddd644dd523978e5d22fb3d62775dc60cd5cdb613540100b1da"
  license "Apache-2.0"
  head "https://github.com/istio/istio.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "711a49032c15fa00ced955fc4c178c46a651aa9b8b54f52a071e657c20ae55e0"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X istio.io/istio/pkg/version.buildVersion=#{version}
      -X istio.io/istio/pkg/version.buildGitRevision=#{tap.user}
      -X istio.io/istio/pkg/version.buildStatus=#{tap.user}
      -X istio.io/istio/pkg/version.buildTag=#{version}
      -X istio.io/istio/pkg/version.buildHub=docker.io/istio
    ]
    system "go", "build", *std_go_args(ldflags:), "./istioctl/cmd/istioctl"

    generate_completions_from_executable(bin/"istioctl", shell_parameter_format: :cobra)
    system bin/"istioctl", "collateral", "--man"
    man1.install Dir["*.1"]
  end

  test do
    assert_equal "client version: #{version}", shell_output("#{bin}/istioctl version --remote=false").strip
  end
end
