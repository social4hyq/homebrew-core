class Leaf < Formula
  desc "General purpose reloader for all projects"
  homepage "https://pkg.go.dev/github.com/vrongmeal/leaf"
  url "https://github.com/vrongmeal/leaf/archive/refs/tags/v1.3.0.tar.gz"
  sha256 "00ba86c1670e4a547d6f584350d41d174452d0679be25828e7835a8da1fe100a"
  license "MIT"
  head "https://github.com/vrongmeal/leaf.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "69589f01475c170f332d39cd1c24caf44c13504e217f0ff49b460ac2fb40c6ff"
  end

  depends_on "go" => :build

  conflicts_with "leaf-proxy", because: "both install `leaf` binaries"

  def install
    system "go", "build", *std_go_args, "./cmd/leaf/main.go"
  end

  test do
    (testpath/"a").write "foo"
    spawn bin/"leaf", "-f", "+ a", "-x", "cp a b"
    sleep 1

    assert_equal "foo", (testpath/"b").read
    (testpath/"a").append_lines "bar"
    sleep 1

    assert_equal "foobar\n", (testpath/"b").read
  end
end
