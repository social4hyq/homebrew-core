class E1s < Formula
  desc "TUI for managing AWS ECS, inspired by k9s"
  homepage "https://github.com/keidarcy/e1s"
  url "https://github.com/keidarcy/e1s/archive/refs/tags/v2.0.0.tar.gz"
  sha256 "d2846602a86b245ca85e0f80d3a02f5cdeb6320d12b87189894f1cfc5531ac28"
  license "MIT"
  head "https://github.com/keidarcy/e1s.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a4c0a5ce7acc74d8761967bbc532323111c87f1ddff0fba02377e6475a787bf2"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/e1s"
  end

  test do
    ENV["AWS_REGION"] = "us-east-1"
    ENV["AWS_ACCESS_KEY_ID"] = "test"
    ENV["AWS_SECRET_ACCESS_KEY"] = "test"

    assert_match version.to_s, shell_output("#{bin}/e1s --version")

    output = shell_output("#{bin}/e1s --json --region us-east-1 2>&1", 1)
    assert_match "e1s failed to start, please check your aws cli credential and permission", output
  end
end
