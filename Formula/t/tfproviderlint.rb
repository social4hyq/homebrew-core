class Tfproviderlint < Formula
  desc "Terraform Provider Lint Tool"
  homepage "https://github.com/bflad/tfproviderlint"
  url "https://github.com/bflad/tfproviderlint/archive/refs/tags/v0.31.0.tar.gz"
  sha256 "9defa750077052ebf1639532e771a9e986b7a53948b6a16cb647ceaf60cfbce1"
  license "MPL-2.0"
  revision 1
  head "https://github.com/bflad/tfproviderlint.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "62bbde6475aac39e54837c4826bcf8ea2e05073b79f74b028e8a6b1bc5623358"
  end

  depends_on "go" => [:build, :test]

  def install
    ldflags = %W[
      -s -w
      -X github.com/bflad/tfproviderlint/version.Version=#{version}
      -X github.com/bflad/tfproviderlint/version.VersionPrerelease=#{"dev" if build.head?}
    ]

    system "go", "build", *std_go_args(ldflags:), "./cmd/tfproviderlint"
  end

  test do
    resource "homebrew-test_resource" do
      url "https://github.com/russellcardullo/terraform-provider-pingdom/archive/refs/tags/v1.1.3.tar.gz"
      sha256 "3834575fd06123846245eeeeac1e815f5e949f04fa08b65c67985b27d6174106"
    end

    testpath.install resource("homebrew-test_resource")
    assert_match "S006: schema of TypeMap should include Elem",
      shell_output("#{bin}/tfproviderlint -fix #{testpath}/... 2>&1", 3)

    assert_match version.to_s, shell_output("#{bin}/tfproviderlint --version")
  end
end
