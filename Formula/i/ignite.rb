class Ignite < Formula
  desc "Build, launch, and maintain any crypto application with Ignite CLI"
  homepage "https://docs.ignite.com/"
  url "https://github.com/ignite/cli/archive/refs/tags/v29.10.1.tar.gz"
  sha256 "3d9edae9cc6b270a75f0bc4aa4a83326defe67126f509965bb2150e5530015a2"
  license "Apache-2.0"
  revision 1
  head "https://github.com/ignite/cli.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2aa14d3d97b9eb3a781b712540d6abce0e37199012b4a540f3e773e30d6f56a3"
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
