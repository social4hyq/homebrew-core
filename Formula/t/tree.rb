class Tree < Formula
  desc "Display directories as trees (with optional color/HTML output)"
  homepage "https://oldmanprogrammer.net/source.php?dir=projects/tree"
  url "https://github.com/Old-Man-Programmer/tree/archive/refs/tags/2.3.2.tar.gz"
  sha256 "22cf32e84e3eb508d97a9e991c2c3cc006b9dcf4afed201d96311c5c57d08fcf"
  license "GPL-2.0-or-later"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1efdfaff7110b70d85dbb0561bf89051838de16ec86a43db548048a998cbe1f9"
  end

  def install
    # OpenHarmony is Linux but uses musl libc which lacks the GNU extension
    # strverscmp. The original check (!__linux__ || __ANDROID__) skips the
    # built-in implementation on Linux, assuming glibc. Check __GLIBC__ instead.
    inreplace "strverscmp.c",
              "#if !defined(__linux__) || defined(__ANDROID__)",
              "#if !defined(__GLIBC__)"
    system "make", "install", "PREFIX=#{prefix}", "MANDIR=#{man}"
  end

  test do
    system bin/"tree", prefix
  end
end
