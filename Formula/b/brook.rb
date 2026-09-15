class Brook < Formula
  desc "Cross-platform strong encryption and not detectable proxy. Zero-Configuration"
  homepage "https://brook.app/"
  url "https://github.com/txthinking/brook/archive/refs/tags/v20270101.tar.gz"
  sha256 "43d8e5476918daa2d35fc63e8b0c94c0c1df8577f1d09103a3ab0f6141f29c0f"
  license "GPL-3.0-only"
  head "https://github.com/txthinking/brook.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d7f56a876900acc6c235d59e3807f64ea2858a217ceb3481f77c052f8e453160"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cli/brook"
  end

  test do
    output = shell_output "#{bin}/brook link --server 1.2.3.4:56789 --password hello"
    # We expect something like "brook://server?password=hello&server=1.2.3.4%3A56789"
    uri = URI(output)
    assert_equal "brook", uri.scheme
    assert_equal "server", uri.host

    query = URI.decode_www_form(uri.query).to_h
    assert_equal "1.2.3.4:56789", query["server"]
    assert_equal "hello", query["password"]
  end
end
