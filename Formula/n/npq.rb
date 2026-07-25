class Npq < Formula
  desc "Audit npm packages before you install them"
  homepage "https://github.com/lirantal/npq"
  url "https://registry.npmjs.org/npq/-/npq-3.23.3.tgz"
  sha256 "4f24e8ed0fd9b017009ad8984f9414e0268644155869256113d08931eeec07d6"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "aec2db206363d0ea58e805b6910fbdaad1eee87fcaf3014c6d62b91fd2d13e99"
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
