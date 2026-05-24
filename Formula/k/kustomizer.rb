class Kustomizer < Formula
  desc "Package manager for distributing Kubernetes configuration as OCI artifacts"
  homepage "https://github.com/stefanprodan/kustomizer"
  url "https://github.com/stefanprodan/kustomizer/archive/refs/tags/v2.2.1.tar.gz"
  sha256 "bba48e2eed5b84111c39b34d9892ffc9f0575b6f6470d50f832f47ff6417bf03"
  license "Apache-2.0"
  head "https://github.com/stefanprodan/kustomizer.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "86cdd71bf7450f49d97e70f416b954b42c25bd5f9d36ab36835ac4d3b14ab652"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.VERSION=#{version}"), "./cmd/kustomizer"

    generate_completions_from_executable(bin/"kustomizer", shell_parameter_format: :cobra)
  end

  test do
    system bin/"kustomizer", "config", "init"
    assert_match "apiVersion: kustomizer.dev/v1", (testpath/".kustomizer/config").read

    output = shell_output("#{bin}/kustomizer list artifact 2>&1", 1)
    assert_match "you must specify an artifact repository e.g. 'oci://docker.io/user/repo'", output
  end
end
