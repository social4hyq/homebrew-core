class TfplugingenOpenapi < Formula
  desc "OpenAPI to Terraform Provider Code Generation Specification"
  homepage "https://github.com/hashicorp/terraform-plugin-codegen-openapi"
  url "https://github.com/hashicorp/terraform-plugin-codegen-openapi/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "30bbf07996185312f8d7ad42163b6f1bcb756adfdd8ec981d63c72c4b7b1e721"
  license "MPL-2.0"
  head "https://github.com/hashicorp/terraform-plugin-codegen-openapi.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4824719e5a875b1e7f01ea1f4ccefe5efd32318b8f195386fa300e5c8a6a0547"
  end

  depends_on "go" => :build

  def install
    commit = build.head? ? Utils.git_short_head : tap.user
    ldflags = "-s -w -X main.commit=#{commit} -X main.version=#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/tfplugingen-openapi"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tfplugingen-openapi --version 2>&1")
    assert_match "OpenAPI specification file is required", shell_output("#{bin}/tfplugingen-openapi generate 2>&1", 1)
  end
end
