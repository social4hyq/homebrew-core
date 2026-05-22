class Decompose < Formula
  desc "Reverse-engineering tool for docker environments"
  homepage "https://github.com/s0rg/decompose"
  url "https://github.com/s0rg/decompose/archive/refs/tags/v1.11.7.tar.gz"
  sha256 "31291c2ce93955bed0f85275c388a7123f2b23c83cf63df6eb4fcc37749daa05"
  license "MIT"
  head "https://github.com/s0rg/decompose.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "41cda90519167f81b4d4336aa29ff72a1a13ee66929556c59f7cebe4210a110e"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.GitTag=#{version} -X main.GitHash=#{tap.user} -X main.BuildDate=#{time.iso8601}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/decompose"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/decompose -version")

    assert_match "Building graph", shell_output("#{bin}/decompose -local 2>&1", 1)
  end
end
