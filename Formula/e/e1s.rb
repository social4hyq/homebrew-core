class E1s < Formula
  desc "TUI for managing AWS ECS, inspired by k9s"
  homepage "https://github.com/keidarcy/e1s"
  url "https://github.com/keidarcy/e1s/archive/refs/tags/v1.0.53.tar.gz"
  sha256 "1f99a3fb44fb784eea7a77aceba7730efa8b0cdac4f1095eebd7be8e355afbda"
  license "MIT"
  head "https://github.com/keidarcy/e1s.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fc3cfa743f66f40653d92085e5365e4be087afd1727845c1ddeae697f387eebf"
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
