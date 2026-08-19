class GhOst < Formula
  desc "Triggerless online schema migration solution for MySQL"
  homepage "https://github.com/github/gh-ost"
  url "https://github.com/github/gh-ost/archive/refs/tags/v1.1.11.tar.gz"
  sha256 "f1cf96257d3f29922a8bd5a906fd742d852cbfb43a0a607e778a9b135cf3133c"
  license "MIT"
  head "https://github.com/github/gh-ost.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5517c57262e1d753d50e2fec21863f89b2d7472ed5745a12b37eee1274a17839"
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
