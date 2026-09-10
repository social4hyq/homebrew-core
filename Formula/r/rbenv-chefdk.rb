class RbenvChefdk < Formula
  desc "Treat ChefDK as another version in rbenv"
  homepage "https://github.com/docwhat/rbenv-chefdk"
  url "https://github.com/docwhat/rbenv-chefdk/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "79b48257f1a24085a680da18803ba6a94a1dd0cb25bd390629006a5fb67f3b69"
  license "MIT"
  revision 2
  head "https://github.com/docwhat/rbenv-chefdk.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "65c2794382e8112350e536940748f89e0a97cd8b66fb9d1add3918ddae626f58"
  end

  depends_on "rbenv"

  def install
    prefix.install Dir["*"]
  end

  test do
    assert_match "rbenv-chefdk.bash", shell_output("rbenv hooks exec")
    assert_match "rbenv-chefdk.bash", shell_output("rbenv hooks rehash")
    assert_match "rbenv-chefdk.bash", shell_output("rbenv hooks which")
  end
end
