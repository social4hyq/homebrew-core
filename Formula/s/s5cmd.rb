class S5cmd < Formula
  desc "Parallel S3 and local filesystem execution tool"
  homepage "https://github.com/peak/s5cmd/"
  url "https://github.com/peak/s5cmd/archive/refs/tags/v2.3.0.tar.gz"
  sha256 "6910763a7320010aa75fe9ef26f622e440c2bd6de41afdbfd64e78c158ca19d4"
  license "MIT"
  head "https://github.com/peak/s5cmd.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "24f6ba6fe2541e97966d88713b89cf0e75f217716358281fa65801fb4d6a0a46"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X=github.com/peak/s5cmd/v2/version.Version=#{version}
      -X=github.com/peak/s5cmd/v2/version.GitCommit=#{tap.user}
    ]
    system "go", "build", *std_go_args(ldflags:)
    generate_completions_from_executable(bin/"s5cmd", "--install-completion")
  end

  test do
    assert_match "no valid providers in chain", shell_output("#{bin}/s5cmd --retry-count 0 ls s3://brewtest 2>&1", 1)
    assert_match version.to_s, shell_output("#{bin}/s5cmd version")
  end
end
