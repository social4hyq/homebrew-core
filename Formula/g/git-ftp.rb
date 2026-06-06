class GitFtp < Formula
  desc "Git-powered FTP client"
  homepage "https://git-ftp.github.io/"
  url "https://github.com/git-ftp/git-ftp/archive/refs/tags/1.6.0.tar.gz"
  sha256 "088b58d66c420e5eddc51327caec8dcbe8bddae557c308aa739231ed0490db01"
  license "GPL-3.0-or-later"
  revision 1
  head "https://github.com/git-ftp/git-ftp.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "61b07cbde0e19bf1da694b80688ca0a2d42bbe2e175d6f6a22939c51fa151bff"
  end

  depends_on "pandoc" => :build
  depends_on "curl"
  depends_on "libssh2"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "make", "prefix=#{prefix}", "install"
    system "make", "-C", "man", "man"
    man1.install "man/git-ftp.1"
  end

  test do
    system bin/"git-ftp", "--help"
  end
end
