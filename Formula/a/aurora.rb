class Aurora < Formula
  desc "Beanstalkd queue server console"
  homepage "https://xuri.me/aurora/"
  url "https://github.com/xuri/aurora/archive/refs/tags/2.2.tar.gz"
  sha256 "90ac08b7c960aa24ee0c8e60759e398ef205f5b48c2293dd81d9c2f17b24ca42"
  license "MIT"
  head "https://github.com/xuri/aurora.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "34367a3fe9940f85fe99035dd7bfb0e8b4ead163d9d3dc2fbff14fef66b396d6"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/aurora -v")
  end
end
