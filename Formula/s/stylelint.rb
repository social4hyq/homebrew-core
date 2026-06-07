class Stylelint < Formula
  desc "Modern CSS linter"
  homepage "https://stylelint.io/"
  url "https://registry.npmjs.org/stylelint/-/stylelint-17.13.0.tgz"
  sha256 "bfb181aaaaca1f5f37b221c1c518bfb7702c474a4380360ef51fae315c80d3b6"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4254d1380f916e2930c8279d0a3f8b5f5a1f6dbef94326f3c0cb70791382c05a"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    (testpath/".stylelintrc").write <<~JSON
      {
        "rules": {
          "block-no-empty": true
        }
      }
    JSON

    (testpath/"test.css").write <<~CSS
      a {
      }
    CSS

    output = shell_output("#{bin}/stylelint test.css 2>&1", 2)
    assert_match "Empty block", output

    assert_match version.to_s, shell_output("#{bin}/stylelint --version")
  end
end
