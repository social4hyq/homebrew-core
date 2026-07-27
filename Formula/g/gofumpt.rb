class Gofumpt < Formula
  desc "Stricter gofmt"
  homepage "https://github.com/mvdan/gofumpt"
  url "https://github.com/mvdan/gofumpt/archive/refs/tags/v0.11.0.tar.gz"
  sha256 "9151983838fa3fbca5a83e3b302e81c68c61e393cb9d3b7e4c297df311bbf394"
  license "BSD-3-Clause"
  head "https://github.com/mvdan/gofumpt.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5b3b30580ce0477f0ab71b5d07c00e87b2750ac1b1c4f5a7378f12e13e8262d6"
  end

  depends_on "go"

  def install
    ldflags = "-s -w -X main.version=#{version}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/gofumpt -version").split.first

    (testpath/"test.go").write <<~GO
      package foo

      func foo() {
        println("bar")

      }
    GO

    (testpath/"expected.go").write <<~GO
      package foo

      func foo() {
      	println("bar")
      }
    GO

    assert_match shell_output("#{bin}/gofumpt test.go"), (testpath/"expected.go").read
  end
end
