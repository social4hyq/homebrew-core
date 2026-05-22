class IamPolicyJsonToTerraform < Formula
  desc "Convert a JSON IAM Policy into terraform"
  homepage "https://github.com/flosell/iam-policy-json-to-terraform"
  url "https://github.com/flosell/iam-policy-json-to-terraform/archive/refs/tags/1.9.2.tar.gz"
  sha256 "63a1a8cc21785e70d830b8fc8289c36250d232c432446e39a25c0da2f2f27067"
  license "Apache-2.0"
  head "https://github.com/flosell/iam-policy-json-to-terraform.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a8f5e8d68eac87902fbed29c3007ce7b6a91b090dfff7b0cf268a7de1e7018cf"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    # test version
    assert_match version.to_s, shell_output("#{bin}/iam-policy-json-to-terraform -version")

    # test functionality
    test_input = '{"Statement":[{"Effect":"Allow","Action":["ec2:Describe*"],"Resource":"*"}]}'
    output = pipe_output(bin/"iam-policy-json-to-terraform", test_input)
    assert_match "ec2:Describe*", output
  end
end
