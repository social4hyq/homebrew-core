class Npq < Formula
  desc "Audit npm packages before you install them"
  homepage "https://github.com/lirantal/npq"
  url "https://registry.npmjs.org/npq/-/npq-3.26.0.tgz"
  sha256 "00e2f33dd048fffff6c195e26af22ac2f120cc3f0a0f12a31b4b51042bc535ca"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "13ac3a4b74efcf0bb5be79aef709e465d56e9bea14b97a7ce200a3e45ac37f84"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/npq --version")

    output = shell_output("#{bin}/npq install npq@3.5.3 --dry-run", 1)
    assert_match "Package Health - Detected an old package", output
  end
end
