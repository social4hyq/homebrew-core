class Tfupdate < Formula
  desc "Update version constraints in your Terraform configurations"
  homepage "https://github.com/minamijoyo/tfupdate"
  url "https://github.com/minamijoyo/tfupdate/archive/refs/tags/v0.10.1.tar.gz"
  sha256 "617a57d9d43642607e1bb5029f6f3bbbd8ce39cc5782d30c7fe32227401c83b8"
  license "MIT"
  head "https://github.com/minamijoyo/tfupdate.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e859a1b8fd975ba095148ab5c819a1a27b899d0135f6d8a8c03c673d04c022a5"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    (testpath/"provider.tf").write <<~HCL
      provider "aws" {
        version = "2.39.0"
      }
    HCL

    system bin/"tfupdate", "provider", "aws", "-v", "2.40.0", testpath/"provider.tf"
    assert_match "2.40.0", File.read(testpath/"provider.tf")

    assert_match version.to_s, shell_output("#{bin}/tfupdate --version")
  end
end
