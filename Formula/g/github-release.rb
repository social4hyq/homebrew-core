class GithubRelease < Formula
  desc "Create and edit releases on Github (and upload artifacts)"
  homepage "https://github.com/github-release/github-release"
  url "https://github.com/github-release/github-release/archive/refs/tags/v0.11.0.tar.gz"
  sha256 "6e6d3d77ce7d6acf6c4e4e0e005c71641ba7c2eb67d9f1f2e2cf2cc5f5c68086"
  license "MIT"
  head "https://github.com/github-release/github-release.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c5f31e35e2b5ace94434ffb632d5013d5f57fbaed9d14480db7cd858f0e75e39"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match "github-release v#{version}", shell_output("#{bin}/github-release --version")

    system bin/"github-release", "info", "--user", "github-release",
                                         "--repo", "github-release",
                                         "--tag",  "v#{version}"
  end
end
