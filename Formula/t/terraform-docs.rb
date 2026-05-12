class TerraformDocs < Formula
  desc "Tool to generate documentation from Terraform modules"
  homepage "https://terraform-docs.io/"
  url "https://github.com/terraform-docs/terraform-docs/archive/refs/tags/v0.24.0.tar.gz"
  sha256 "e3c971a1f2a02732d964e19e65c901b4e02cca62c4b748c05d22e9690d055540"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f9120b7ee76bcd4a213c179a6b9b2d84337882876638e37ec7c5431c86b156eb"
  end

  depends_on "go" => :build

  def install
    system "make", "build"
    cpu = Hardware::CPU.intel? ? "amd64" : Hardware::CPU.arch.to_s
    os = OS.kernel_name.downcase

    bin.install "bin/#{os}-#{cpu}/terraform-docs"

    generate_completions_from_executable(bin/"terraform-docs", "completion")
  end

  test do
    (testpath/"main.tf").write <<~HCL
      /**
       * Module usage:
       *
       *      module "foo" {
       *        source = "github.com/foo/baz"
       *        subnet_ids = "${join(",", subnet.*.id)}"
       *      }
       */

      variable "subnet_ids" {
        description = "a comma-separated list of subnet IDs"
      }

      variable "security_group_ids" {
        default = "sg-a, sg-b"
      }

      variable "amis" {
        default = {
          "us-east-1" = "ami-8f7687e2"
          "us-west-1" = "ami-bb473cdb"
          "us-west-2" = "ami-84b44de4"
          "eu-west-1" = "ami-4e6ffe3d"
          "eu-central-1" = "ami-b0cc23df"
          "ap-northeast-1" = "ami-095dbf68"
          "ap-southeast-1" = "ami-cf03d2ac"
          "ap-southeast-2" = "ami-697a540a"
        }
      }

      // The VPC ID.
      output "vpc_id" {
        value = "vpc-5c1f55fd"
      }
    HCL
    system bin/"terraform-docs", "json", testpath
  end
end
