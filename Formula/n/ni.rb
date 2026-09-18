class Ni < Formula
  desc "Selects the right Node package manager based on lockfiles"
  homepage "https://github.com/antfu-collective/ni"
  url "https://registry.npmjs.org/@antfu/ni/-/ni-30.6.0.tgz"
  sha256 "239e6b5c626cbb7405d5605e304504534b43c8a7584aeeba9a58e1a55caa1eb0"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "42a3907cb89ee5845b04d64c26fd47f06af28c3add7074d1ab3efd566fc8e573"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")

    generate_completions_from_executable(bin/"nr", shell_parameter_format: "--completion-")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ni --version")

    (testpath/"package.json").write <<~JSON
      {
        "name": "fake-package",
        "version": "1.0.0",
        "description": "Fake package for testing",
        "license": "MIT"
      }
    JSON

    (testpath/"package-lock.json").write <<~JSON
      {
        "name": "fake-package",
        "version": "1.0.0",
        "lockfileVersion": 3,
        "packages": {},
        "dependencies": {}
      }
    JSON

    assert_match "up to date, audited 1 package", shell_output(bin/"ni")
  end
end
