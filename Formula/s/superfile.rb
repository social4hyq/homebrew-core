class Superfile < Formula
  desc "Modern and pretty fancy file manager for the terminal"
  homepage "https://superfile.netlify.app/"
  url "https://github.com/yorukot/superfile/archive/refs/tags/v1.6.0.tar.gz"
  sha256 "7340ce9e3e7db401164310dd5d2d1dfa3ccf76118ac49d192b0fac2a292c5b0d"
  license "MIT"

  # Upstream creates releases that use a stable tag (e.g., `v1.2.3`) but are
  # labeled as "pre-release" on GitHub before the version is released, so it's
  # necessary to use the `GithubLatest` strategy.
  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2e7e75c756fc8a93fb283fc9cc2e15d10317a937356d1ee0739b54acfb065dc7"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/"spf")
  end

  test do
    # superfile is a GUI application
    assert_match version.to_s, shell_output("#{bin}/spf -v")
  end
end
