class Rush < Formula
  desc "GNU's Restricted User SHell"
  homepage "https://www.gnu.org.ua/software/rush/"
  url "https://ftpmirror.gnu.org/gnu/rush/rush-2.4.tar.xz"
  mirror "https://ftp.gnu.org/gnu/rush/rush-2.4.tar.xz"
  sha256 "fa95af9d2c7b635581841cc27a1d27af611f60dd962113a93d23a8874aa060f4"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fd15098ffefdde6612963d254091d9f10891496d1d799d5d377f5c2bd711b442"
  end

  conflicts_with "rush-parallel", because: "both install `rush` binaries"

  def install
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system sbin/"rush", "-h"
  end
end
