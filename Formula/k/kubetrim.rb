class Kubetrim < Formula
  desc "Trim your KUBECONFIG automatically"
  homepage "https://github.com/alexellis/kubetrim"
  url "https://github.com/alexellis/kubetrim/archive/refs/tags/v0.0.2.tar.gz"
  sha256 "24455f11699c61760613f630ded0d395cdf5b2d3925a08a730878819f353e00f"
  license "MIT"
  head "https://github.com/alexellis/kubetrim.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "df949108825277885483e5668b28923be37048cb94f2cb008b2479b944d8e889"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/alexellis/kubetrim/pkg.Version=#{version} -X github.com/alexellis/kubetrim/pkg.GitCommit=#{tap.user}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/kubetrim --help")

    # fake k8s configuration
    (testpath/".kube/config").write <<~YAML
      apiVersion: v1
      clusters:
        - cluster:
            insecure-skip-tls-verify: true
            server: 'https://localhost:6443'
          name: test-cluster
      contexts:
        - context:
            cluster: test-cluster
            user: test-user
          name: test-context
      current-context: test-context
      kind: Config
      preferences: {}
      users:
        - name: test-user
          user:
            token: test-token
    YAML

    output = shell_output("#{bin}/kubetrim -write=false")
    assert_match "failed to connect to cluster", output
  end
end
