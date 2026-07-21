class Quicktype < Formula
  desc "Generate types and converters from JSON, Schema, and GraphQL"
  homepage "https://github.com/glideapps/quicktype"
  url "https://registry.npmjs.org/quicktype/-/quicktype-25.1.0.tgz"
  sha256 "914fcddc444479a6ee5119fa19dda4e38eaadbb173c9d3acf1dd9b295a8f1670"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b296aab5e7aa9723b7f2485c9d159c6f554b2e08ada4df427a3dd6832c6381b6"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    (testpath/"sample.json").write <<~JSON
      {
        "i": [0, 1],
        "s": "quicktype"
      }
    JSON
    output = shell_output("#{bin}/quicktype --lang typescript --src sample.json")
    assert_match "i: number[];", output
    assert_match "s: string;", output
  end
end
