class Jscpd < Formula
  desc "Copy/paste detector for programming source code"
  homepage "https://github.com/kucherenko/jscpd"
  url "https://github.com/kucherenko/jscpd/archive/refs/tags/v5.1.0.tar.gz"
  sha256 "b81896e79ae12e24daf60b8addf7d38d9242ad411ce20b77257d763a03472868"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bce749a4c31d2462eedb89e40599f22d66562b063fe9f4da8b232fa02ba37653"
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
