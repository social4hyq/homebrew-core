class RbenvBinstubs < Formula
  desc "Make rbenv aware of bundler binstubs"
  homepage "https://github.com/Purple-Devs/rbenv-binstubs"
  url "https://github.com/Purple-Devs/rbenv-binstubs/archive/refs/tags/v1.5.tar.gz"
  sha256 "305000b8ba5b829df1a98fc834b7868b9e817815c661f429b0e28c1f613f4d0c"
  license "MIT"
  revision 1
  head "https://github.com/Purple-Devs/rbenv-binstubs.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c6cc89a679336db7ae0cc99ebb06b47d9d49fb4bdf058e60f37fe047f231745e"
  end

  depends_on "rbenv"

  def install
    prefix.install Dir["*"]
  end

  test do
    assert_match "rbenv-binstubs.bash", shell_output("rbenv hooks exec")
  end
end
