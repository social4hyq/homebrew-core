class Oauth2l < Formula
  desc "Simple CLI for interacting with Google oauth tokens"
  homepage "https://github.com/google/oauth2l"
  url "https://github.com/google/oauth2l/archive/refs/tags/v1.3.4.tar.gz"
  sha256 "102c552c02109d440e27e6af9744e80d5d49981fbcf2ea7dcc76b6373b673095"
  license "Apache-2.0"
  head "https://github.com/google/oauth2l.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c3fd3471555e079a6121fe71ff2fc6ad8d43fec4f19acf5be0e22d16cd72a802"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match "Invalid Value", shell_output("#{bin}/oauth2l info abcd1234")
  end
end
