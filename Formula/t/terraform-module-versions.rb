class TerraformModuleVersions < Formula
  desc "CLI that checks Terraform code for module updates"
  homepage "https://github.com/keilerkonzept/terraform-module-versions"
  url "https://github.com/keilerkonzept/terraform-module-versions/archive/refs/tags/v3.3.13.tar.gz"
  sha256 "b85fbeb788c6fca0c328a29a1aab839cd556a7506105f544326a6e322d2aaf80"
  license "MIT"
  head "https://github.com/keilerkonzept/terraform-module-versions.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "19549d5145a412b6e380f296d6c9a44c3676277ee79a7c91b66e4b31574af94b"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/terraform-module-versions version")

    assert_match "TYPE", shell_output("#{bin}/terraform-module-versions list")
    assert_match "UPDATE?", shell_output("#{bin}/terraform-module-versions check")
  end
end
