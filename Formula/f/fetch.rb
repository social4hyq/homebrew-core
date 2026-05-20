class Fetch < Formula
  desc "Download assets from a commit, branch, or tag of GitHub repositories"
  homepage "https://www.gruntwork.io/"
  url "https://github.com/gruntwork-io/fetch/archive/refs/tags/v0.4.8.tar.gz"
  sha256 "8192dddb375e2a8765e54e27c65b544068b35bd349f9ad669d6269734f3b5f76"
  license "MIT"
  head "https://github.com/gruntwork-io/fetch.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "902a79e8b0ed3f26200328ed23d96d04c7358274a2296c0faf0480875c5c6039"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-X main.VERSION=v#{version}")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/fetch --version")

    repo_url = "https://github.com/gruntwork-io/fetch"

    assert_match "Downloading asset SHA256SUMS to SHA256SUMS",
      shell_output("#{bin}/fetch --repo=\"#{repo_url}\" --tag=\"v0.4.6\" --release-asset=\"SHA256SUMS\" . 2>&1")
  end
end
