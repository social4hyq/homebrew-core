class GitCodereview < Formula
  desc "Tool for working with Gerrit code reviews"
  homepage "https://pkg.go.dev/golang.org/x/review/git-codereview"
  url "https://github.com/golang/review/archive/refs/tags/v1.20.0.tar.gz"
  sha256 "0361d7c03b773b64f03650948dec1643f0a755b77445e16b849f7bda290ba4e0"
  license "BSD-3-Clause"
  head "https://github.com/golang/review.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "18091657694545a80583bcb5a1a2aa26368898bfa2f44358c9d1a23666c75627"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./git-codereview"
  end

  test do
    system "git", "init"
    system "git", "codereview", "hooks"
    assert_match "git-codereview hook-invoke", (testpath/".git/hooks/commit-msg").read
  end
end
