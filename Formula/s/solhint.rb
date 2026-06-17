class Solhint < Formula
  desc "Linter for Solidity code"
  homepage "https://protofire.github.io/solhint/"
  url "https://registry.npmjs.org/solhint/-/solhint-6.2.2.tgz"
  sha256 "10d456dea41e32dd4f8d53d2b07db63203846af0e36cd14f9cb07142b571ebd2"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "59a2cd26008b57135864305995d24a4bd3c3e350a1e10b6d73c55d918862cb32"
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
