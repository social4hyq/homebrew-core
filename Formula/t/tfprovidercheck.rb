class Tfprovidercheck < Formula
  desc "CLI to prevent malicious Terraform Providers from being executed"
  homepage "https://github.com/suzuki-shunsuke/tfprovidercheck"
  url "https://github.com/suzuki-shunsuke/tfprovidercheck/archive/refs/tags/v1.0.7.tar.gz"
  sha256 "99dddd4317b99c3f304ed206b68de5c13840995dd04218968fe693ec77d20cd2"
  license "MIT"
  head "https://github.com/suzuki-shunsuke/tfprovidercheck.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dcdc2d0e19b33ada1f63326ea71c70ba713246070696d1541890d15ce22b9e96"
  end

  depends_on "go" => :build
  depends_on "opentofu" => :test

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}"), "./cmd/tfprovidercheck"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tfprovidercheck -version")

    (testpath/"test.tf").write <<~HCL
      terraform {
        required_version = ">= 1.0"

        required_providers {
          aws = {
            source = "hashicorp/aws"
            version = "~> 5"
          }
        }
      }

      provider "aws" {
        region = var.aws_region
      }
    HCL

    # Only google provider and azurerm provider are allowed
    (testpath/".tfprovidercheck.yaml").write <<~YAML
      providers:
        - name: registry.terraform.io/hashicorp/google
          version: ">= 4.0.0"
        - name: registry.terraform.io/hashicorp/azurerm
    YAML

    system "tofu", "init"
    json_output = shell_output("tofu version -json")
    output = pipe_output("#{bin}/tfprovidercheck 2>&1", json_output, 1)
    assert_match "Terraform Provider is disallowed", output
  end
end
