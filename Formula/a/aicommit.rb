class Aicommit < Formula
  desc "AI-powered commit message generator"
  homepage "https://github.com/coder/aicommit"
  url "https://github.com/coder/aicommit/archive/refs/tags/v0.6.5.tar.gz"
  sha256 "b89c00eabd881344a0e1ee3fe2d5bbf5005cfd19881f5d3a4b23bc8dd0a98a0b"
  license "CC0-1.0"
  head "https://github.com/coder/aicommit.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "65e0cd862aafb3d730ca0cac854779800d46da35a8775b3bac2548a9971be616"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.Version=v#{version}"), "./cmd/aicommit"
  end

  test do
    assert_match "aicommit v#{version}", shell_output("#{bin}/aicommit version")

    system "git", "init", "--bare", "."
    assert_match "err: $OPENAI_API_KEY is not set", shell_output("#{bin}/aicommit 2>&1", 1)
  end
end
