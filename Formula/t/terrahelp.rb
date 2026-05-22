class Terrahelp < Formula
  desc "Tool providing extra functionality for Terraform"
  homepage "https://github.com/opencredo/terrahelp"
  url "https://github.com/opencredo/terrahelp/archive/refs/tags/v0.7.5.tar.gz"
  sha256 "bfcffdf06e1db075872a6283d1f1cc6858b8139bf10dd480969b419aa6fc01f7"
  license "Apache-2.0"
  head "https://github.com/opencredo/terrahelp.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0d637b35f2dd93827b474085c11e7a5e8026e254ac69068847a1745805c70861"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args, "-mod=vendor"
  end

  test do
    tf_vars = testpath/"terraform.tfvars"
    tf_vars.write <<~EOS
      tf_sensitive_key_1         = "sensitive-value-1-AK#%DJGHS*G"
    EOS

    tf_output = testpath/"tf.out"
    tf_output.write <<~EOS
      Refreshing Terraform state in-memory prior to plan...
      The refreshed state will be used to calculate this plan, but
      will not be persisted to local or remote state storage.

      ...

      <= data.template_file.example
          rendered:  "<computed>"
          template:  "..."
          vars.%:    "1"
          vars.msg1: "sensitive-value-1-AK#%DJGHS*G"

      Plan: 0 to add, 0 to change, 0 to destroy.
    EOS

    output = pipe_output("#{bin}/terrahelp mask --tfvars #{tf_vars}", tf_output.read).strip

    assert_match("vars.msg1: \"******\"", output, "expecting sensitive value to be masked")
    refute_match(/sensitive-value-1-AK#%DJGHS\*G/, output, "not expecting sensitive value to be presentt")
  end
end
