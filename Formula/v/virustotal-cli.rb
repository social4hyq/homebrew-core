class VirustotalCli < Formula
  desc "Command-line interface for VirusTotal"
  homepage "https://github.com/VirusTotal/vt-cli"
  url "https://github.com/VirusTotal/vt-cli/archive/refs/tags/1.3.1.tar.gz"
  sha256 "3d95ddab1da71ee769ec65e3ed087994fc837d2d234f9c2640c669c8ce8c7d7a"
  license "Apache-2.0"

  # Upstream creates releases that use a stable tag (e.g., `v1.2.3`) but are
  # labeled as "pre-release" on GitHub before the version is released, so it's
  # necessary to use the `GithubLatest` strategy.
  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c91065b5eb0fd4af71237e63276008166c672f2bc79e9da009e4439d61639aba"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X cmd.Version=#{version}", output: bin/"vt"), "./vt"

    generate_completions_from_executable(bin/"vt", "completion")
  end

  test do
    output = shell_output("#{bin}/vt url #{homepage} 2>&1", 1)
    assert_match "Error: An API key is needed", output
  end
end
