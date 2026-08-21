class Oauth2l < Formula
  desc "Simple CLI for interacting with Google oauth tokens"
  homepage "https://github.com/google/oauth2l"
  url "https://github.com/google/oauth2l/archive/refs/tags/v1.3.5.tar.gz"
  sha256 "d7e2c5ba8af23f465dc318b12886665fede1ff06e6980636cc93eab70e267144"
  license "Apache-2.0"
  head "https://github.com/google/oauth2l.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a8ce837c606177ba2a48ed14c380515a0d3a841fd35976583275535e2abc5cce"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match "Invalid Value", shell_output("#{bin}/oauth2l info abcd1234")
  end
end
