class ChainBench < Formula
  desc "Software supply chain auditing tool based on CIS benchmark"
  homepage "https://github.com/aquasecurity/chain-bench"
  url "https://github.com/aquasecurity/chain-bench/archive/refs/tags/v0.1.10.tar.gz"
  sha256 "5bfeaacd9cf7d272e88597135bff7f329d455a810aaf2b6a763ac55e18d383c1"
  license "Apache-2.0"
  head "https://github.com/aquasecurity/chain-bench.git", branch: "main"

  # There can be a notable gap between when a version is tagged and a
  # corresponding release is created, so we check the "latest" release instead
  # of the Git tags.
  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "33aff1c0faaed5f8b85f0c44a30055e9b833cf9d0c7af624a9f0ead6f53b987a"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X=main.version=#{version}"), "./cmd/chain-bench"

    generate_completions_from_executable(bin/"chain-bench", shell_parameter_format: :cobra)
  end

  test do
    repo_url = "https://github.com/Homebrew/homebrew-core"
    assert_match "Fetch Starting", shell_output("#{bin}/chain-bench scan --repository-url #{repo_url}")

    assert_match version.to_s, shell_output("#{bin}/chain-bench --version")
  end
end
