class Kompose < Formula
  desc "Tool to move from `docker-compose` to Kubernetes"
  homepage "https://kompose.io/"
  url "https://github.com/kubernetes/kompose/archive/refs/tags/v1.38.0.tar.gz"
  sha256 "1a6eb3e9a5084d0ce6d1a81628b314686b7cfa41124bace13eb188865f7640a0"
  license "Apache-2.0"
  head "https://github.com/kubernetes/kompose.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1e55ca4e038dfa9abc1bbf798dcea6cdd8a070b54dd8ed0a15e2302253dc5f7b"
  end

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = OS.mac? ? "1" : "0"
    system "go", "build", *std_go_args(ldflags: "-s -w")

    generate_completions_from_executable(bin/"kompose", "completion")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/kompose version")
  end
end
