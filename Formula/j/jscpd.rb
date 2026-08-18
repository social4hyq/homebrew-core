class Jscpd < Formula
  desc "Copy/paste detector for programming source code"
  homepage "https://github.com/kucherenko/jscpd"
  url "https://github.com/kucherenko/jscpd/archive/refs/tags/v5.0.16.tar.gz"
  sha256 "4421519c60876b203643a80f70d9e36a202a1437fc5687ba8f80ba1f26de165b"
  license "MIT"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9f46cf2738b1ffe018ca7aedf60233110c66f4a6477696dd504a8d44519d4eef"
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
