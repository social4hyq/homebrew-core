class OrgFormation < Formula
  desc "Infrastructure as Code (IaC) tool for AWS Organizations"
  homepage "https://github.com/org-formation/org-formation-cli"
  url "https://registry.npmjs.org/aws-organization-formation/-/aws-organization-formation-1.0.17.tgz"
  sha256 "347b3b10690569cbd36104ea612f0de9b9092afd0e81115818f648f68235ec4a"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dcda5201b597bd2a47b576ba29abe42563c8f6b24be28b0083c8938460984f35"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/org-formation --version")

    ENV["AWS_REGION"] = "us-east-1"
    ENV["AWS_ACCESS_KEY_ID"] = "test"
    ENV["AWS_SECRET_ACCESS_KEY"] = "test"

    output = shell_output("#{bin}/org-formation init test-init 2>&1", 1)
    assert_match "The security token included in the request is invalid", output
  end
end
