class Httpx < Formula
  desc "Fast and multi-purpose HTTP toolkit"
  homepage "https://github.com/projectdiscovery/httpx"
  url "https://github.com/projectdiscovery/httpx/archive/refs/tags/v1.12.0.tar.gz"
  sha256 "b29319c085537047bff8acf72c6cd4ecf17585ede97f4afdde2304431c74e64e"
  license "MIT"
  head "https://github.com/projectdiscovery/httpx.git", branch: "dev"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f3f9c65b5a23e395eff7e6031c977a3d4faf47b20b7ffd6c0b48d6e5c71405eb"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/httpx"
  end

  test do
    output = JSON.parse(shell_output("#{bin}/httpx -silent -title -json -u example.org"))
    assert_equal 200, output["status_code"]
    assert_equal "Example Domain", output["title"]
  end
end
