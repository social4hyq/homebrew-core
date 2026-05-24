class Ignite < Formula
  desc "Build, launch, and maintain any crypto application with Ignite CLI"
  homepage "https://docs.ignite.com/"
  url "https://github.com/ignite/cli/archive/refs/tags/v29.10.0.tar.gz"
  sha256 "9acb18354e9be72dd6e79c9b9cbfa3c8157061f55e354e59646f20b63aeb89f5"
  license "Apache-2.0"
  head "https://github.com/ignite/cli.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6ab2bb618bb9403ff30e400f7026446d72f24c6bc6916adb9cb757de344848e8"
  end

  depends_on "go"
  depends_on "node"

  def install
    system "go", "build", "-mod=readonly", *std_go_args(ldflags: "-s -w", output: bin/"ignite"), "./ignite/cmd/ignite"
  end

  test do
    ENV["DO_NOT_TRACK"] = "1"
    system bin/"ignite", "s", "chain", "mars", "--no-module", "--skip-proto"
    sleep 5
    sleep 10 if OS.mac? && Hardware::CPU.intel?
    assert_path_exists testpath/"mars/go.mod"
  end
end
