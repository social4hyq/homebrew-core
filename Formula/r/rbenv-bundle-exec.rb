class RbenvBundleExec < Formula
  desc "Integrate rbenv and bundler"
  homepage "https://github.com/maljub01/rbenv-bundle-exec"
  url "https://github.com/maljub01/rbenv-bundle-exec/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "2da08cbb1d8edecd1bcf68005d30e853f6f948c54ddb07bada67762032445cf3"
  license "MIT"
  revision 1
  head "https://github.com/maljub01/rbenv-bundle-exec.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "acf0a694c7bb4b020067e450bf680d004b5b878ac81b2bbcd82294d25ae2c854"
  end

  depends_on "rbenv"

  def install
    prefix.install Dir["*"]
  end

  test do
    assert_match "bundle-exec.bash", shell_output("rbenv hooks exec")
  end
end
