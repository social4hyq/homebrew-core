class Picoclaw < Formula
  desc "Ultra-efficient personal AI assistant in Go"
  homepage "https://picoclaw.io/"
  url "https://github.com/sipeed/picoclaw/archive/refs/tags/v0.3.1.tar.gz"
  sha256 "df66f2f9a6fecf6f1396311b4a7881afc34d5f4209e2bebd6d91fb2b142d78d0"
  license "MIT"
  head "https://github.com/sipeed/picoclaw.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "172c900a80d4199eb88a3951378d45d8630720797267888f155db657df3e53ea"
  end

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "0"

    system "go", "generate", "./cmd/picoclaw/internal/onboard"

    ldflags = "-s -w -X github.com/sipeed/picoclaw/pkg/config.Version=#{version}"
    tags = "goolm,stdjson"
    system "go", "build", *std_go_args(ldflags:, tags:), "./cmd/picoclaw"
  end

  service do
    run [opt_bin/"picoclaw", "gateway"]
    keep_alive true
  end

  test do
    ENV["HOME"] = testpath
    assert_match version.to_s, shell_output("#{bin}/picoclaw version")

    system bin/"picoclaw", "onboard"
    assert_path_exists testpath/".picoclaw/config.json"
    assert_path_exists testpath/".picoclaw/workspace/AGENT.md"

    assert_match "picoclaw Status", shell_output("#{bin}/picoclaw status")
  end
end
