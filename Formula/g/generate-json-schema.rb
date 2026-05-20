class GenerateJsonSchema < Formula
  desc "Generate a JSON Schema from Sample JSON"
  homepage "https://github.com/Nijikokun/generate-schema"
  url "https://registry.npmjs.org/generate-schema/-/generate-schema-2.6.0.tgz"
  sha256 "1ddbf91aab2d649108308d1de7af782d9270a086919edb706f48d0216d51374a"
  license "MIT"
  head "https://github.com/Nijikokun/generate-schema.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "134893d88f8e5d59f1e7888eb5b2bf30a77ea81c87c933a7a01e06fcac233138"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    (testpath/"test.json").write <<~JSON
      {
          "id": 2,
          "name": "An ice sculpture",
          "price": 12.50,
          "tags": ["cold", "ice"],
          "dimensions": {
              "length": 7.0,
              "width": 12.0,
              "height": 9.5
          },
          "warehouseLocation": {
              "latitude": -78.75,
              "longitude": 20.4
          }
      }
    JSON
    assert_match "schema.org", shell_output("#{bin}/generate-schema test.json", 1)
  end
end
