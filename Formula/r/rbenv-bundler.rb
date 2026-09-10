class RbenvBundler < Formula
  desc "Makes shims aware of bundle install paths"
  homepage "https://github.com/carsomyr/rbenv-bundler"
  url "https://github.com/carsomyr/rbenv-bundler/archive/refs/tags/1.0.1.tar.gz"
  sha256 "6840d4165242da4606cd246ee77d484a91ee926331c5a6f840847ce189f54d74"
  license "Apache-2.0"
  revision 1
  head "https://github.com/carsomyr/rbenv-bundler.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7d8bf5c0de2fa4cda1014d71974513eb19b74f65dcbc2197e2e0f747165485b7"
  end

  depends_on "rbenv"

  def install
    prefix.install Dir["*"]
  end

  test do
    assert_match "bundler.bash", shell_output("rbenv hooks exec")
  end
end
