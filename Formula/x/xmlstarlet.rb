class Xmlstarlet < Formula
  desc "XML command-line utilities"
  homepage "https://xmlstar.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/xmlstar/xmlstarlet/1.6.1/xmlstarlet-1.6.1.tar.gz"
  sha256 "15d838c4f3375332fd95554619179b69e4ec91418a3a5296e7c631b7ed19e7ca"
  license "MIT"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "10e9da4069cbfe3bf1694055e31ee2379ee52ab2d532664e23b8d6c5f82c47bf"
  end

  uses_from_macos "libxml2"
  uses_from_macos "libxslt"

  # Apply Gentoo patch to fix build with libxml2 >= 2.14
  # Upstream ref: https://sourceforge.net/p/xmlstar/patches/23/
  patch do
    url "https://raw.githubusercontent.com/gentoo/gentoo/ea0797e1f96c7a0e17fc1af24131a0e0c923d08a/app-text/xmlstarlet/files/xmlstarlet-1.6.1-libxml2-2.14.0-compile.patch"
    sha256 "5d2f35d16447e5d4258110a6e83f788ae52c9dc6b3b20eee84977626105dce1e"
  end

  def install
    ENV.append_to_cflags "-Wno-incompatible-function-pointer-types" if DevelopmentTools.clang_build_version >= 1500
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--mandir=#{man}"
    system "make"
    system "make", "install"
    bin.install_symlink "xml" => "xmlstarlet"
  end

  test do
    system bin/"xmlstarlet", "--version"
  end
end
