class RbenvGemset < Formula
  desc "KISS yet powerful gem/set management for curious engineers and Ruby hackers"
  homepage "https://github.com/jf/rbenv-gemset"
  url "https://github.com/jf/rbenv-gemset/archive/refs/tags/v0.5.102.tar.gz"
  sha256 "193f560fe169b338a63d0bc38cc56ec05bf8639f47073ba487352b1058668e5a"
  license :public_domain
  head "https://github.com/jf/rbenv-gemset.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9ba184e694e46e8edda5e542b8fd14730fcc761207b3a8334c938e28cf4bd2aa"
  end

  depends_on "rbenv"

  def install
    prefix.install Dir["*"]
  end

  test do
    output = shell_output("rbenv hooks exec")
    assert_match "exec.bash", output
  end
end
