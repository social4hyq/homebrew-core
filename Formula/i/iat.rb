class Iat < Formula
  desc "Converts many CD-ROM image formats to ISO9660"
  homepage "https://sourceforge.net/projects/iat.berlios/"
  url "https://downloads.sourceforge.net/project/iat.berlios/iat-0.1.7.tar.bz2"
  sha256 "fb72c42f4be18107ec1bff8448bd6fac2a3926a574d4950a4d5120f0012d62ca"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "68bad733da5ab49c5fcc3f259db3fb0c74aee3d2451bee16d9db31567c1e79f8"
  end

  def install
    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}",
                          "--includedir=#{include}/iat"
    system "make", "install"
  end

  test do
    system bin/"iat", "--version"
  end
end
