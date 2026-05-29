class Lsdvd < Formula
  desc "Read the content info of a DVD"
  homepage "https://sourceforge.net/projects/lsdvd/"
  url "https://git.code.sf.net/p/lsdvd/git.git",
      tag:      "0.21",
      revision: "de9cf2379335076368cc848de04a60279d944b68"
  license "GPL-2.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8dba4674f432fce45e95d43294109e5bd723de6777c6c32d3b8be1bff1a4b46f"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "pkgconf" => :build
  depends_on "libdvdcss"
  depends_on "libdvdread"
  depends_on "libxml2"

  # Move `dvdlogger` function out of `main()`, as Clang (rightfully) does not allow nested functions
  # Can be removed once this has been merged: https://sourceforge.net/p/lsdvd/git/merge-requests/2/
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/443cea9c2797b473f4069aad0e12ff06521333b7/Patches/lsdvd/logging.patch"
    sha256 "5879230867a18b52264428b064e2b5f96423563da1409909f85e0f2163e0ae94"
  end

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--mandir=#{man}", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"lsdvd", "--help"
  end
end
