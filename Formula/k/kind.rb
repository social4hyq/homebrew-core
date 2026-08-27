class Kind < Formula
  desc "Run local Kubernetes cluster in Docker"
  homepage "https://kind.sigs.k8s.io/"
  url "https://github.com/kubernetes-sigs/kind/archive/refs/tags/v0.33.0.tar.gz"
  sha256 "8b00b127eb567f30b028cb032d236d990404e9fd83ce7798db7f9c7a305fab34"
  license "Apache-2.0"
  head "https://github.com/kubernetes-sigs/kind.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5bc3586d64ef078021842947a65340a7cdd0c78e761d122025d8b7b824ebe25e"
  end

  depends_on "go" => :build
  depends_on "docker" => :test

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")

    generate_completions_from_executable(bin/"kind", shell_parameter_format: :cobra)
  end

  test do
    ENV["DOCKER_HOST"] = "unix://#{testpath}/invalid.sock"

    # Should error out as creating a kind cluster requires root
    status_output = shell_output("#{bin}/kind get kubeconfig --name homebrew 2>&1", 1)
    assert_match "failed to connect to the docker API", status_output
  end
end
