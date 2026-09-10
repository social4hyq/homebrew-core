class GoBindata < Formula
  desc "Small utility that generates Go code from any file"
  homepage "https://github.com/kevinburke/go-bindata"
  url "https://github.com/kevinburke/go-bindata/archive/refs/tags/v4.0.2.tar.gz"
  sha256 "ac343c4b316b234b8ea354d86eb3c7ded2da4fe8f40d45f60391d289c66cd950"
  license "BSD-2-Clause"
  revision 1
  head "https://github.com/kevinburke/go-bindata.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "08e0a57dc4999742dbf05da8bf116fbb7c4ea6cf9c4cfb2d7e6019d3e78f4115"
  end

  depends_on "go"

  def install
    system "go", "build", *std_go_args, "./go-bindata"
  end

  test do
    (testpath/"data").write "hello world"
    system bin/"go-bindata", "-o", "data.go", "data"
    File.delete(testpath/"data")
    assert_path_exists testpath/"data.go"

    (testpath/"testbindata.go").write <<~GO
      package main

      func main() {
        println("data:", string(MustAsset("data")))
      }
    GO

    assert_equal "data: hello world", shell_output("go run data.go testbindata.go 2>&1").chomp

    assert_match version.to_s, shell_output("#{bin}/go-bindata --version")
  end
end
