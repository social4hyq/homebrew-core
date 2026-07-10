class Labctl < Formula
  desc "CLI tool for interacting with iximiuz labs and playgrounds"
  homepage "https://github.com/iximiuz/labctl"
  url "https://github.com/iximiuz/labctl/archive/refs/tags/v0.1.98.tar.gz"
  sha256 "d6acc5ab7ce378a3e3441f8e3dcd4c052417fe2d62ef87ff000c33703bc2118f"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3e1e1982fd7db0bc542e9324fa7f0546dfc784ba63f2a4186affcb2c2bcea967"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.version=#{version}
      -X main.commit=#{tap.user}
      -X main.date=#{time.iso8601}
    ]
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/labctl --version")

    assert_match "Not logged in.", shell_output("#{bin}/labctl auth whoami 2>&1")
    assert_match "authentication required.", shell_output("#{bin}/labctl playground list 2>&1", 1)
  end
end
