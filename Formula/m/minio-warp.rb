class MinioWarp < Formula
  desc "S3 benchmarking tool"
  homepage "https://github.com/minio/warp"
  url "https://github.com/minio/warp/archive/refs/tags/v1.8.0.tar.gz"
  sha256 "5f0f8cbffccb4685cb5d1b191337369becf8fdd65277b68b189eb1e9eba6647b"
  license "AGPL-3.0-or-later"
  head "https://github.com/minio/warp.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "60e8edfd0bdc3bca07e51a1e923d6bd04f8ab39b0c823c2d1c590a75e76b876c"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/minio/warp/pkg.ReleaseTag=v#{version}
      -X github.com/minio/warp/pkg.CommitID=#{tap.user}
      -X github.com/minio/warp/pkg.Version=#{version}
      -X github.com/minio/warp/pkg.ReleaseTime=#{time.iso8601}
    ]

    system "go", "build", *std_go_args(ldflags:, output: bin/"warp")
  end

  test do
    output = shell_output("#{bin}/warp list --no-color 2>&1", 1)
    assert_match "warp: <ERROR> Error preparing server", output

    assert_match version.to_s, shell_output("#{bin}/warp --version")
  end
end
