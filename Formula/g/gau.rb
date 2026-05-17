class Gau < Formula
  desc "Open Threat Exchange, Wayback Machine, and Common Crawl URL fetcher"
  homepage "https://github.com/lc/gau"
  url "https://github.com/lc/gau/archive/refs/tags/v2.2.4.tar.gz"
  sha256 "537abafca9065a7ed5d93aa7722d85da0815abf6b08c2d1494483171558ce3f7"
  license "MIT"
  head "https://github.com/lc/gau.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "32b537f5341c0f51c54f7b92e055106c8fc471892272d7a8d0032c26acf09e86"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/gau"
  end

  test do
    output = shell_output("#{bin}/gau --providers urlscan brew.sh")
    assert_match %r{https?://brew\.sh(/|:)?.*}, output

    assert_match version.to_s, shell_output("#{bin}/gau --version")
  end
end
