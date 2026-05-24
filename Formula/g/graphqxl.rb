class Graphqxl < Formula
  desc "Language for creating big and scalable GraphQL server-side schemas"
  homepage "https://gabotechs.github.io/graphqxl"
  url "https://github.com/gabotechs/graphqxl/archive/refs/tags/v0.40.2.tar.gz"
  sha256 "2ddc205e3943e97273984e64bdac3d41c70b87eb408976d7d2108163fca35d4e"
  license "MIT"
  head "https://github.com/gabotechs/graphqxl.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "440f87b6648cc2f15c5954dac2726f0d1347286667163ee9a6cb8295e67a2c55"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    test_file = testpath/"test.graphqxl"
    test_file.write "type MyType { foo: String! }"
    system bin/"graphqxl", test_file
    assert_equal "type MyType {\n  foo: String!\n}\n\n", (testpath/"test.graphql").read
  end
end
