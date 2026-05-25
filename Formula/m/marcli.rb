class Marcli < Formula
  desc "Parse MARC (ISO 2709) files"
  homepage "https://github.com/hectorcorrea/marcli"
  url "https://github.com/hectorcorrea/marcli/archive/refs/tags/v1.3.1.tar.gz"
  sha256 "944c7c389d384a9515799bb688cb9ced80344709758a42c714f726957785a1c4"
  license "MIT"
  head "https://github.com/hectorcorrea/marcli.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cc7e34ebc2cc32643533568ab7e42ae4517f56529e926ea67bc6cba78be1679a"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/marcli"
  end

  test do
    resource "testdata" do
      url "https://raw.githubusercontent.com/hectorcorrea/marcli/5434a2f85c6f03771f92ad9f0d5af5241f3385a6/data/test_1a.mrc"
      sha256 "7359455ae04b1619f3879fe39eb22ad4187fb3550510f71cb4f27693f60cf386"
    end

    resource("testdata").stage do
      assert_equal "=650  \\0$aCoal$xAnalysis.\n=650  \\0$aCoal$xSampling.\n\n",
      shell_output("#{bin}/marcli -file test_1a.mrc -fields 650")
    end
  end
end
