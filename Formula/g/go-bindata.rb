class GoBindata < Formula
  desc "Small utility that generates Go code from any file"
  homepage "https://github.com/kevinburke/go-bindata"
  url "https://github.com/kevinburke/go-bindata/archive/refs/tags/v4.0.2.tar.gz"
  sha256 "ac343c4b316b234b8ea354d86eb3c7ded2da4fe8f40d45f60391d289c66cd950"
  license "BSD-2-Clause"
  head "https://github.com/kevinburke/go-bindata.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "08e0a57dc4999742dbf05da8bf116fbb7c4ea6cf9c4cfb2d7e6019d3e78f4115"
  end

  depends_on "go"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./go-bindata"
  end

  test do
    (testpath/"data").write "hello world"
    system bin/"go-bindata", "-o", "data.go", "data"
    assert_path_exists testpath/"data.go"
    assert_match '\xff\xff\x85\x11\x4a', (testpath/"data.go").read
  end
end
