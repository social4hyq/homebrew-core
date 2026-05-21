class Sqsmover < Formula
  desc "AWS SQS Message mover"
  homepage "https://github.com/mercury2269/sqsmover"
  url "https://github.com/mercury2269/sqsmover/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "217203f626399c67649f99af52eff6d6cdd9280ec5e2631e1de057e1bd0cdd0d"
  license "Apache-2.0"
  head "https://github.com/mercury2269/sqsmover.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0ab291ab8755086dbbbb786185a3c60b766081e60ec98cbae5076cb27a5c3806"
  end

  depends_on "go" => :build

  # Fix build with Go 1.18.
  # Remove with the next release.
  patch do
    url "https://github.com/mercury2269/sqsmover/commit/2791c1912e4e262dca981dcf2219305b3d0e784a.patch?full_index=1"
    sha256 "effd7cc9422b64944abada78cbd163c8900b3dd1254427cbdee76e106e8e540b"
  end

  def install
    ldflags = %W[
      -s -w
      -X main.version=#{version}
      -X main.date=#{time.iso8601}
      -X main.builtBy=#{tap.user}
    ].join(" ")

    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    ENV["AWS_REGION"] = "us-east-1"
    assert_match "Failed to resolve source queue.",
      shell_output("#{bin}/sqsmover --source test-dlq --destination test --profile test 2>&1")

    assert_match version.to_s, shell_output("#{bin}/sqsmover --version 2>&1")
  end
end
