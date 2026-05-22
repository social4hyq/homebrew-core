class TerraformCleaner < Formula
  desc "Tiny utility which detects unused variables in your terraform modules"
  homepage "https://github.com/sylwit/terraform-cleaner"
  url "https://github.com/sylwit/terraform-cleaner/archive/refs/tags/v0.0.4.tar.gz"
  sha256 "61628133831ec667aa37cd5fc1a34a3a2c31e4e997d5f41fdf380fe3e017ab55"
  license "MIT"
  head "https://github.com/sylwit/terraform-cleaner.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8f8d80ed4eca1dfdb7e86d9727dbc43a97ff82ac232ebbf8de8f449c3d37ca50"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
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

      variable "aws_region" {
        type    = string
        default = "us-east-1"
      }

      variable "foo" {
        type    = string
        default = "unused"
      }
    HCL

    output = shell_output("#{bin}/terraform-cleaner --unused-only")
    assert_equal <<~EOS.chomp, output

       🚀 Module: .
       👉 1 variables found
      foo : 0

      1 modules processed
    EOS
  end
end
