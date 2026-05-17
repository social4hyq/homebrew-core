class DepTree < Formula
  desc "Tool for visualizing dependencies between files and enforcing dependency rules"
  homepage "https://github.com/gabotechs/dep-tree"
  url "https://github.com/gabotechs/dep-tree/archive/refs/tags/v0.23.4.tar.gz"
  sha256 "84f303594bce854527fe85208867a5060314ff3b24990d7c0f2846d364d81d4a"
  license "MIT"
  head "https://github.com/gabotechs/dep-tree.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7c0a71555f06321bd54d4a9095cdc5245315640c19b03218a7339d20000eeb0a"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    (testpath/"foo.js").write <<~JS
      import { bar } from './bar'
    JS
    (testpath/"bar.js").write <<~JS
      export const bar = 'bar'
    JS
    (testpath/"package.json").write <<~JSON
      { "name": "foo" }
    JSON
    expected = <<~JSON
      {
        "tree": {
          "foo.js": {
            "bar.js": null
          }
        },
        "circularDependencies": [],
        "errors": {}
      }
    JSON

    assert_equal expected, shell_output("#{bin}/dep-tree tree --json #{testpath}/foo.js")
  end
end
