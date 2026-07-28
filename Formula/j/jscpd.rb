class Jscpd < Formula
  desc "Copy/paste detector for programming source code"
  homepage "https://github.com/kucherenko/jscpd"
  url "https://github.com/kucherenko/jscpd/archive/refs/tags/v5.0.14.tar.gz"
  sha256 "c7a339017af0687e2f399d55216721376a0c24d88cce1efd9effb524ec96537a"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1bf7c01d8eed73540ce3e3dc05340b9827d0aef276be473b809c27ad0e9f6a68"
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
