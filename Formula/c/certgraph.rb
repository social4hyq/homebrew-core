class Certgraph < Formula
  desc "Crawl the graph of certificate Alternate Names"
  homepage "https://github.com/lanrat/certgraph"
  url "https://github.com/lanrat/certgraph/archive/refs/tags/v0.1.2.tar.gz"
  sha256 "233b6bf6c081d88c63ed26b2d11d09a74e55f3dfc860823fdf946dc455a1d135"
  license "GPL-2.0-or-later"
  version_scheme 1
  head "https://github.com/lanrat/certgraph.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4e106781ea1a694f3e5146bde49d241c334006d7fdc5b896242cb1891e672728"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}")
  end

  test do
    output = shell_output("#{bin}/certgraph github.io")
    assert_match "githubusercontent.com", output
    assert_match "pages.github.com", output

    assert_match version.to_s, shell_output("#{bin}/certgraph --version")
  end
end
