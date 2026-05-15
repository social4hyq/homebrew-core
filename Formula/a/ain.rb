class Ain < Formula
  desc "HTTP API client for the terminal"
  homepage "https://github.com/jonaslu/ain"
  url "https://github.com/jonaslu/ain/archive/refs/tags/v1.6.0.tar.gz"
  sha256 "a60ce846edc6f8e5429c3cf14faf57f170b757c6ab13d8f36d64235a1959e6c8"
  license "MIT"
  head "https://github.com/jonaslu/ain.git", branch: "main"

  # Upstream creates releases that use a stable tag (e.g., `v1.2.3`) but are
  # labeled as "pre-release" on GitHub before the version is released, so it's
  # necessary to use the `GithubLatest` strategy.
  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6404ab3370852f9c76e3ddc12750d119a88e7f9fd6976face83d51086daf2d0e"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.gitSha=#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/ain"
  end

  test do
    assert_match "http://localhost:${PORT}", shell_output("#{bin}/ain -b")
    assert_match version.to_s, shell_output("#{bin}/ain -v")
  end
end
