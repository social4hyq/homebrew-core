class Oauth2l < Formula
  desc "Simple CLI for interacting with Google oauth tokens"
  homepage "https://github.com/google/oauth2l"
  url "https://github.com/google/oauth2l/archive/refs/tags/v1.3.3.tar.gz"
  sha256 "a27f643949baa9f057bceb490c170d589728d3bda0a3066f57e17bb02b383cd9"
  license "Apache-2.0"
  head "https://github.com/google/oauth2l.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5441d20cc5664d33c4eacca0af2289639e1803ee6e85c8d658ac4ad82bb79ea4"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match "Invalid Value", shell_output("#{bin}/oauth2l info abcd1234")
  end
end
