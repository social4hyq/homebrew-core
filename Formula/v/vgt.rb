class Vgt < Formula
  desc "Visualising Go Tests"
  homepage "https://github.com/roblaszczak/vgt"
  url "https://github.com/roblaszczak/vgt/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "c442980c2205d45d527205fc9f832f4d27f4d3e8c815f471f428266f6fcf33c6"
  license "MIT"
  revision 1
  head "https://github.com/roblaszczak/vgt.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3a4c7843df0ec02957f2b22b20adb1bc6e550ea93546e99a769dd38fe0a319cd"
  end

  depends_on "go"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    (testpath/"test.go").write <<~EOS
      package test

      import "testing"

      func TestExample(t *testing.T) {
        t.Log("Hello from sample test")
      }
    EOS

    output = pipe_output("#{bin}/vgt --print-html", "go test -json #{testpath}/sample_test.go", 0)
    assert_match "Test Results (0s 0 passed, 0 failed)", output
  end
end
