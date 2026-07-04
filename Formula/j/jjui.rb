class Jjui < Formula
  desc "TUI for interacting with the Jujutsu version control system"
  homepage "https://github.com/idursun/jjui"
  url "https://github.com/idursun/jjui/archive/refs/tags/v0.10.8.tar.gz"
  sha256 "964fc721c5494237a8259b044001327d7c93aa58aba07f9444d873f05d18d21d"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "39d33541c1f7c813643ed3951482de01d283ebf79c2d11c7e1cb7339801af175"
  end

  depends_on "go" => :build
  depends_on "jj"

  def install
    ENV["CGO_ENABLED"] = OS.mac? ? "1" : "0"
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.Version=#{version}"), "./cmd/jjui"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/jjui -version")
    assert_match "There is no jj repo in", shell_output("#{bin}/jjui 2>&1", 1)
  end
end
