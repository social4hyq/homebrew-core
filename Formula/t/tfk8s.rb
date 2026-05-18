class Tfk8s < Formula
  desc "Kubernetes YAML manifests to Terraform HCL converter"
  homepage "https://github.com/jrhouston/tfk8s"
  url "https://github.com/jrhouston/tfk8s/archive/refs/tags/v0.1.10.tar.gz"
  sha256 "be2680e76311ac7dd814a1bb0dceb486e3511d8d68845421338f9fcf5a92d5f9"
  license "MIT"
  head "https://github.com/jrhouston/tfk8s.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "919f1ce67a6f8f41033e683cf3ede6804e0e8b8e36900fe08bc2b643742d7cff"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.toolVersion=#{version}")
  end

  test do
    (testpath/"input.yml").write <<~YAML
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: test
      data:
        TEST: test
    YAML

    expected = <<~HCL
      resource "kubernetes_manifest" "configmap_test" {
        manifest = {
          "apiVersion" = "v1"
          "data" = {
            "TEST" = "test"
          }
          "kind" = "ConfigMap"
          "metadata" = {
            "name" = "test"
          }
        }
      }
    HCL

    system bin/"tfk8s", "-f", "input.yml", "-o", "output.tf"
    assert_equal expected, File.read("output.tf")

    assert_match version.to_s, shell_output("#{bin}/tfk8s --version")
  end
end
