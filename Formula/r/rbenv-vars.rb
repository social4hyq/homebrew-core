class RbenvVars < Formula
  desc "Safely sets global and per-project environment variables"
  homepage "https://github.com/rbenv/rbenv-vars"
  url "https://github.com/rbenv/rbenv-vars/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "9e6a5726aad13d739456d887a43c220ba9198e672b32536d41e884c0a54b4ddb"
  license "MIT"
  revision 2
  head "https://github.com/rbenv/rbenv-vars.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f62eb64606dd9e94e5272d31a9605201148fc647c5a5e2e6a8021c05af8b192a"
  end

  depends_on "rbenv"

  def install
    prefix.install Dir["*"]
  end

  test do
    assert_match "rbenv-vars.bash", shell_output("rbenv hooks exec")
  end
end
