class Jid < Formula
  desc "Json incremental digger"
  homepage "https://github.com/simeji/jid"
  url "https://github.com/simeji/jid/archive/refs/tags/v1.1.2.tar.gz"
  sha256 "b86b8026e8aa216f31d31d8b9f6548be0533c4b20d555c65066db405075af081"
  license "MIT"
  head "https://github.com/simeji/jid.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c7f8f4ac3a9c3e5f47967dd74f05a7f725ae1ef37e153b2acf575e62b6f451da"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "cmd/jid/jid.go"
  end

  test do
    assert_match "jid version v#{version}", shell_output("#{bin}/jid --version")
  end
end
