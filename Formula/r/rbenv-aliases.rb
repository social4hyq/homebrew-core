class RbenvAliases < Formula
  desc "Make aliases for Ruby versions"
  homepage "https://github.com/tpope/rbenv-aliases"
  url "https://github.com/tpope/rbenv-aliases/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "12e89bc4499e85d8babac2b02bc8b66ceb0aa3f8047b26728a3eca8a6030273d"
  license "MIT"
  revision 1
  head "https://github.com/tpope/rbenv-aliases.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "802ad86183297b36c56aa364c24175c20380cb22e7f540ec1509112fdbcb6978"
  end

  depends_on "rbenv"

  def install
    prefix.install Dir["*"]
  end

  test do
    assert_match "autoalias.bash", shell_output("rbenv hooks install")
  end
end
