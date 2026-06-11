class Jscpd < Formula
  desc "Copy/paste detector for programming source code"
  homepage "https://github.com/kucherenko/jscpd"
  url "https://github.com/kucherenko/jscpd/archive/refs/tags/v5.0.6.tar.gz"
  sha256 "65c1d1124a896df2028c0aca2d7ba4b27daac7c6b32c0d51fdda92df60cdce2c"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "894ca2c205029227bdda54e618480245306606982e16b922451a54feffc880b8"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "rust/crates/cpd")
  end

  test do
    test_file = testpath/"test.js"
    test_file2 = testpath/"test2.js"
    test_file.write <<~JAVASCRIPT
      console.log("Hello, world!");
    JAVASCRIPT
    test_file2.write <<~JAVASCRIPT
      console.log("Hello, brewtest!");
    JAVASCRIPT

    output = shell_output("#{bin}/jscpd --min-lines 1 #{testpath}/*.js 2>&1")
    assert_match "Found 0 clones", output

    assert_match version.to_s, shell_output("#{bin}/jscpd --version")
  end
end
