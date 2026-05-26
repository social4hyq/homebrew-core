class Webify < Formula
  desc "Wrapper for shell commands as web services"
  homepage "https://github.com/beefsack/webify"
  url "https://github.com/beefsack/webify/archive/refs/tags/v1.5.0.tar.gz"
  sha256 "66805a4aef4ed0e9c49e711efc038e2cd4e74aa2dc179ea93b31dc3aa76e6d7b"
  license "MIT"
  head "https://github.com/beefsack/webify.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "83ed98549e559564bdc5e09e63c1295d57d520f5a282bb6eccf14a13b93b32bc"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args
  end

  test do
    port = free_port
    spawn bin/"webify", "-addr=:#{port}", "cat"
    sleep 1
    assert_equal "Homebrew", shell_output("curl -s -d Homebrew http://localhost:#{port}")
  end
end
