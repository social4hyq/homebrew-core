class TerraformInventory < Formula
  desc "Go app which generates a dynamic Ansible inventory from a Terraform state file"
  homepage "https://github.com/adammck/terraform-inventory"
  url "https://github.com/adammck/terraform-inventory/archive/refs/tags/v0.10.tar.gz"
  sha256 "8bd8956da925d4f24c45874bc7b9012eb6d8b4aa11cfc9b6b1b7b7c9321365ac"
  license "MIT"
  head "https://github.com/adammck/terraform-inventory.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7fa87ffbc024a706e09f7e1d7ae59541db9afff1b5a5d7c62a9ec0885195ff79"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.build_version=#{version}")
  end

  test do
    example = <<~JSON
      {
          "version": 1,
          "serial": 1,
          "modules": [
              {
                  "path": [
                      "root"
                  ],
                  "outputs": {},
                  "resources": {
                      "aws_instance.example_instance": {
                          "type": "aws_instance",
                          "primary": {
                              "id": "i-12345678",
                              "attributes": {
                                  "public_ip": "1.2.3.4"
                              },
                              "meta": {
                                  "schema_version": "1"
                              }
                          }
                      }
                  }
              }
          ]
      }
    JSON
    (testpath/"example.tfstate").write(example)
    assert_match(/example_instance/, shell_output("#{bin}/terraform-inventory --list example.tfstate"))
  end
end
