class GhOst < Formula
  desc "Triggerless online schema migration solution for MySQL"
  homepage "https://github.com/github/gh-ost"
  url "https://github.com/github/gh-ost/archive/refs/tags/v1.1.10.tar.gz"
  sha256 "70222d979e6d442befbbc11cdb16d420bc84ae7be277d79648c420e4458251c4"
  license "MIT"
  head "https://github.com/github/gh-ost.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4dd5b2c15deb65a16dd333a876c2f0d1ef354cbd49117de340f6fff63d962ba2"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.AppVersion=#{version} -X main.GitCommit=#{tap.user}"
    system "go", "build", *std_go_args(ldflags:), "./go/cmd/gh-ost"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/gh-ost -version")

    error_output = shell_output("#{bin}/gh-ost --database invalid " \
                                "--table invalid --execute --alter 'ADD COLUMN c INT' 2>&1", 1)
    assert_match "connect: connection refused", error_output
  end
end
