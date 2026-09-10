class Tree < Formula
  desc "Display directories as trees (with optional color/HTML output)"
  homepage "https://oldmanprogrammer.net/source.php?dir=projects/tree"
  url "https://github.com/Old-Man-Programmer/tree/archive/refs/tags/2.3.2.tar.gz"
  sha256 "22cf32e84e3eb508d97a9e991c2c3cc006b9dcf4afed201d96311c5c57d08fcf"
  license "GPL-2.0-or-later"
  revision 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d4783c4b2549ed5423cf90f4ec32c7dcee9be855f13efad7a845b631f407c66f"
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
