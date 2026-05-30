class Hz < Formula
  desc "Golang HTTP framework for microservices"
  homepage "https://github.com/cloudwego/hertz"
  url "https://github.com/cloudwego/hertz/archive/refs/tags/cmd/hz/v0.9.7.tar.gz"
  sha256 "c2d894db10414648cd4d131ca1405cb1fde0dcdd3287fbd4c4623c9916ae6717"
  license "Apache-2.0"
  head "https://github.com/cloudwego/hertz.git", branch: "develop"

  livecheck do
    url :stable
    regex(%r{^cmd/hz/v?(\d+(?:\.\d+)+)$}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3b95306aeb790d59a0ce9aabcf8b9922fa823b51109b462f4705de0ab6ee5604"
  end

  depends_on "go" => [:build, :test]

  def install
    cd "cmd/hz" do
      system "go", "build", *std_go_args(ldflags: "-s -w")
    end
    bin.install_symlink bin/"hz" => "thrift-gen-hertz"
    bin.install_symlink bin/"hz" => "protoc-gen-hertz"
  end

  test do
    ENV["GOPATH"] = testpath

    output = shell_output("#{bin}/hz --version 2>&1")
    assert_match "hz version v#{version}", output

    system bin/"hz", "new", "--mod=test"
    assert_path_exists testpath/"main.go"
    refute_predicate (testpath/"main.go").size, :zero?
  end
end
