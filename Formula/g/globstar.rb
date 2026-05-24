class Globstar < Formula
  desc "Static analysis toolkit for writing and running code checkers"
  homepage "https://globstar.dev"
  url "https://github.com/DeepSourceCorp/globstar/archive/refs/tags/v0.7.2.tar.gz"
  sha256 "72e587b847e75fa751510bacfdf25d035ff3d6290878f1b51d26eeafa03d39e9"
  license "MIT"
  head "https://github.com/DeepSourceCorp/globstar.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "49bde8d5f2f94ec14c0877a79d684a2275c35c1025d9a2c1bfbb25b1c379015f"
  end

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "1" if OS.linux? && Hardware::CPU.arm?

    system "make", "generate-registry"
    system "go", "build", *std_go_args(ldflags: "-s -w -X globstar.dev/pkg/cli.version=#{version}"), "./cmd/globstar"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/globstar --version")

    output = shell_output("#{bin}/globstar check 2>&1")
    assert_match "Checker directory .globstar does not exist", output
  end
end
