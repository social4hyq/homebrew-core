class Tfschema < Formula
  desc "Schema inspector for Terraform/OpenTofu providers"
  homepage "https://github.com/minamijoyo/tfschema"
  url "https://github.com/minamijoyo/tfschema/archive/refs/tags/v0.7.10.tar.gz"
  sha256 "7d028adc987d4cb7896556df1d727270396e9790a734700fbd867c2e3a62c211"
  license "MIT"
  head "https://github.com/minamijoyo/tfschema.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bb2e6864ff05a25ea2d3daa72e15154f0c05f4852924fa5cbea9a3f3ecc484fe"
  end

  depends_on "go" => :build
  depends_on "opentofu" => :test

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    (testpath/"provider.tf").write "provider \"aws\" {}"
    system Formula["opentofu"].bin/"tofu", "init"
    assert_match "permissions_boundary", shell_output("#{bin}/tfschema resource show aws_iam_user")

    assert_match version.to_s, shell_output("#{bin}/tfschema --version")
  end
end
