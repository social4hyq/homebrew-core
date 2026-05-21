class Libdmtx < Formula
  desc "Data Matrix library"
  homepage "https://libdmtx.sourceforge.net/"
  url "https://github.com/dmtx/libdmtx/archive/refs/tags/v0.7.8.tar.gz"
  sha256 "2394bf1d1d693a5a4ca3cfcc1bb28a4d878bdb831ea9ca8f3d5c995d274bdc39"
  license "BSD-2-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dc91ca88aaba0c68e3a0cb43a134d3e5655e1bb401e2f01c0334bd0b62920cab"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", *std_configure_args
    system "make"
    system "make", "install"
  end

  def test
    system "true"
  end
end
