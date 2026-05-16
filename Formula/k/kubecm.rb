class Kubecm < Formula
  desc "KubeConfig Manager"
  homepage "https://kubecm.cloud"
  url "https://github.com/sunny0826/kubecm/archive/refs/tags/v0.35.1.tar.gz"
  sha256 "fe6c08075c45ee595c59b7f87e6e226c2ee8a0a237f22f409b55a1b83ffe037b"
  license "Apache-2.0"
  head "https://github.com/sunny0826/kubecm.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "50370899fbf13020acecfe9ee7d9ad2a587aeab23a82b2db57800b99a38c3bd1"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/sunny0826/kubecm/version.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"kubecm", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/kubecm version")
    # Should error out as switch context need kubeconfig
    assert_match "Error: open", shell_output("#{bin}/kubecm switch 2>&1", 1)
  end
end
