class Inform6 < Formula
  desc "Design system for interactive fiction"
  homepage "https://inform-fiction.org/inform6.html"
  url "https://ifarchive.org/if-archive/infocom/compilers/inform6/source/inform-6.44-r7.tar.gz"
  version "6.44-r7"
  sha256 "3e1f94e5c726f5f59cf086756dc14e66a3fd281ddbac75ead611d45aa57e4bdb"
  license "Artistic-2.0"
  head "https://gitlab.com/DavidGriffith/inform6unix.git", branch: "master"

  livecheck do
    url "https://ifarchive.org/indexes/if-archive/infocom/compilers/inform6/source/"
    regex(/href=.*?inform[._-]v?(\d+(?:[.-]\d+)+(?:[._-]r\d+)?)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c36164046d22572fe08c2b70f31285675bdc13270f85a1a062456019a631d84e"
  end

  def install
    # Parallel install fails because of: https://gitlab.com/DavidGriffith/inform6unix/-/issues/26
    ENV.deparallelize
    system "make", "PREFIX=#{prefix}", "MAN_PREFIX=#{man}", "MANDIR=#{man1}", "install"
  end

  test do
    resource "homebrew-test_resource" do
      url "https://inform-fiction.org/examples/Adventureland/Adventureland.inf"
      sha256 "3961388ff00b5dfd1ccc1bb0d2a5c01a44af99bdcf763868979fa43ba3393ae7"
    end

    resource("homebrew-test_resource").stage do
      system bin/"inform", "Adventureland.inf"
      assert_path_exists Pathname.pwd/"Adventureland.z5"
    end
  end
end
