class TransifexCli < Formula
  desc "Transifex command-line client"
  homepage "https://github.com/transifex/cli"
  url "https://github.com/transifex/cli/archive/refs/tags/v1.6.17.tar.gz"
  sha256 "759320acd621991046533089bb77320202853cc97b860ab7783040d0e4d5e34f"
  license "Apache-2.0"
  head "https://github.com/transifex/cli.git", branch: "devel"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ed98dbf5f0d68cb52d8723fcca8ba011abb5cdc293cd36c769729daa1ea53749"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/transifex/cli/internal/txlib.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:, output: bin/"tx")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tx --version")
    assert_match "Successful creation of '.tx/config' file", shell_output("#{bin}/tx init")
    assert_match "https://app.transifex.com", (testpath/".tx/config").read
  end
end
