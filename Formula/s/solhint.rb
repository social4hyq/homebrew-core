class Solhint < Formula
  desc "Linter for Solidity code"
  homepage "https://protofire.github.io/solhint/"
  url "https://registry.npmjs.org/solhint/-/solhint-6.2.4.tgz"
  sha256 "c3060df2c802f344bfcdde6d5181aae393baa16f0fa5e29022a0168fc4d5baf6"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "429efeed4c1722bf76ffb1a3cadfffb338df0b2a3fb021fa44da0ed9365cdb8c"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    test_config = testpath/".solhint.json"
    test_config.write <<~JSON
      {
        "rules": {
          "no-empty-blocks": "error"
        }
      }
    JSON

    (testpath/"test.sol").write <<~SOLIDITY
      pragma solidity ^0.4.0;
      contract Test {
        function test() {
        }
      }
    SOLIDITY
    assert_match "error  Code contains empty blocks  no-empty-blocks",
      shell_output("#{bin}/solhint --config #{test_config} test.sol 2>&1", 1)
  end
end
