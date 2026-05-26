class SafCli < Formula
  desc "CLI for the MITRE Security Automation Framework (SAF)"
  homepage "https://saf-cli.mitre.org"
  url "https://registry.npmjs.org/@mitre/saf/-/saf-1.6.0.tgz"
  sha256 "9d176c4c0caff994e70f1a32bebb4d81597cbff5d07b75f4257cdba2a6bd192c"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "abf411cf246e95303698595f9a8d5ee08143f42478aee37b76bc9527c79cc3d4"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/saf --version")

    output = shell_output("#{bin}/saf scan")
    assert_match "Visit https://saf.mitre.org/#/validate to explore and run inspec profiles", output
  end
end
