class RbenvCtags < Formula
  desc "Automatically generate ctags for rbenv Ruby stdlibs"
  homepage "https://github.com/tpope/rbenv-ctags"
  url "https://github.com/tpope/rbenv-ctags/archive/refs/tags/v1.0.2.tar.gz"
  sha256 "94b38c277a5de3f53aac0e7f4ffacf30fb6ddeb31c0597c1bcd78b0175c86cbe"
  license "MIT"
  revision 1
  head "https://github.com/tpope/rbenv-ctags.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "587effd704a6f0f2f25c585ac14186cd0062b1be33b6935cc871d5e3cf04940e"
  end

  depends_on "rbenv"
  depends_on "universal-ctags"

  def install
    prefix.install Dir["*"]
  end

  test do
    assert_match "ctags.bash", shell_output("rbenv hooks install")
  end
end
