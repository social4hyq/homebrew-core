class Tfsec < Formula
  desc "Static analysis security scanner for your terraform code"
  homepage "https://aquasecurity.github.io/tfsec/latest/"
  url "https://github.com/aquasecurity/tfsec/archive/refs/tags/v1.28.14.tar.gz"
  sha256 "61fe8ee670cceaf45d85c2789da66616d0045f8dbba4ec2b9db453436f9b9804"
  license "MIT"
  revision 1
  head "https://github.com/aquasecurity/tfsec.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "059bf8b2dc360c9668322783050906d966b9d567d3e96619914d3d2608c42ef8"
  end

  depends_on "go" => :build

  def install
    system "scripts/install.sh", "v#{version}"
    bin.install "tfsec"
  end

  test do
    (testpath/"good/brew-validate.tf").write <<~HCL
      resource "aws_alb_listener" "my-alb-listener" {
        port     = "443"
        protocol = "HTTPS"
      }
    HCL
    (testpath/"bad/brew-validate.tf").write <<~HCL
      resource "aws_security_group_rule" "world" {
        description = "A security group triggering tfsec AWS006."
        type        = "ingress"
        cidr_blocks = ["0.0.0.0/0"]
      }
    HCL

    good_output = shell_output("#{bin}/tfsec #{testpath}/good")
    assert_match "No problems detected!", good_output
    bad_output = shell_output("#{bin}/tfsec #{testpath}/bad 2>&1", 1)
    assert_match "1 potential problem(s) detected.", bad_output
  end
end
