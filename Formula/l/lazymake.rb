class Lazymake < Formula
  desc "Modern TUI for Makefiles"
  homepage "https://lazymake.vercel.app/"
  url "https://github.com/rshelekhov/lazymake/archive/refs/tags/v0.4.1.tar.gz"
  sha256 "49dc29635990385fef22717d23c986a62803dc2afeeb428e0a1910711b169c37"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "35fd08fc908c3dc575e9ae9a95389a55dfd5e16bfa66736ed4117623543cdcf8"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/lazymake"
  end

  test do
    # lazymake is a TUI, to verify the command is working we check the help output
    assert_match "Usage:", shell_output("#{bin}/lazymake --help")
  end
end
