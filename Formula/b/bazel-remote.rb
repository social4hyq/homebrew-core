class BazelRemote < Formula
  desc "Remote cache for Bazel"
  homepage "https://github.com/buchgr/bazel-remote/"
  url "https://github.com/buchgr/bazel-remote/archive/refs/tags/v2.6.1.tar.gz"
  sha256 "7e554caa4c9c7033459acc053ee8470208012223e72c81aabe2b48fb0e6c3fbc"
  license "Apache-2.0"
  head "https://github.com/buchgr/bazel-remote.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f44895c3aad6237a6a01342bad8d48aa8891af8ce0a21c6b3f9a231be66b6b59"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.gitCommit=#{version}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    ENV["BAZEL_REMOTE_DIR"] = "test"
    ENV["BAZEL_REMOTE_MAX_SIZE"] = "10"

    begin
      pid = spawn bin/"bazel-remote"
      sleep 2
      assert_path_exists testpath/"test", "Failed to create test directory"
    ensure
      Process.kill("SIGINT", pid)
      Process.wait(pid)
    end
  end
end
