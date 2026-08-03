class Jid < Formula
  desc "Json incremental digger"
  homepage "https://github.com/simeji/jid"
  url "https://github.com/simeji/jid/archive/refs/tags/v1.1.3.tar.gz"
  sha256 "5d1092316e13eb3029a76ffd749cf1ad8642511fe3762f00635feea32d24b7d1"
  license "MIT"
  head "https://github.com/simeji/jid.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "94e0cc47d3a931691918b62d3a947b906cb5fb258353cf54c51b1bd92e302e61"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "cmd/jid/jid.go"
  end

  test do
    assert_match "jid version v#{version}", shell_output("#{bin}/jid --version")
  end
end
