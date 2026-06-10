class Snapraid < Formula
  desc "Backup program for disk arrays"
  homepage "https://www.snapraid.it/"
  url "https://github.com/amadvance/snapraid/releases/download/v14.7/snapraid-14.7.tar.gz"
  sha256 "fe4c71d444bade85fe390d2a58de1ea34b53109278b96fb19bc9ac9133eb07ff"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "84805170e48f8d1dfc3738f568f3ff42ebe4d4044a3df5b99cc7746bab42f7b7"
  end

  head do
    url "https://github.com/amadvance/snapraid.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  def install
    system "./autogen.sh" if build.head?
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/snapraid --version")
  end
end
