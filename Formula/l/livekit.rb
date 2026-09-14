class Livekit < Formula
  desc "Scalable, high-performance WebRTC server"
  homepage "https://livekit.io"
  url "https://github.com/livekit/livekit/archive/refs/tags/v1.13.7.tar.gz"
  sha256 "b42f34b095dff22639a40256c3f98fd563fdbce5d497e449ceb06ee010de88c5"
  license "Apache-2.0"
  head "https://github.com/livekit/livekit.git", branch: "master"

  # Upstream creates releases that use a stable tag (e.g., `v1.2.3`) but are
  # labeled as "pre-release" on GitHub before the version is released, so it's
  # necessary to use the `GithubLatest` strategy.
  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cff2f1d67ab456e7a5a96dfd1b0e40710e5c4077f243f2a6b603c14e16f876de"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/"livekit-server"), "./cmd/server"
  end

  test do
    http_port = free_port
    random_key = "R4AA2dwX3FrMbyY@My3X&Hsmz7W)LuQy"
    spawn bin/"livekit-server", "--keys", "test: #{random_key}", "--config-body", "port: #{http_port}"
    sleep 3
    assert_match "OK", shell_output("curl -s http://localhost:#{http_port}")

    output = shell_output("#{bin}/livekit-server --version")
    assert_match "livekit-server version #{version}", output
  end
end
