class Asnmap < Formula
  desc "Quickly map organization network ranges using ASN information"
  homepage "https://github.com/projectdiscovery/asnmap"
  url "https://github.com/projectdiscovery/asnmap/archive/refs/tags/v1.1.1.tar.gz"
  sha256 "3d48657278a1f1fa27528e66d5cf4bcb6f3ee7ce26a518fcaf6ce9a9c9a8e317"
  license "MIT"
  head "https://github.com/projectdiscovery/asnmap.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "baec837d2f13ed58f8fb6f098d36cdc43eb3b7a8e51d04ca935b92a12f13f9f7"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/asnmap"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/asnmap -version 2>&1")

    # Skip linux CI test as test not working there
    return if OS.linux? && ENV["HOMEBREW_GITHUB_ACTIONS"]

    # need API key for IP lookup test, thus just run empty binary test
    assert_match "no input defined", shell_output("#{bin}/asnmap 2>&1", 1)
  end
end
