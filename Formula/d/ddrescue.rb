class Ddrescue < Formula
  desc "GNU data recovery tool"
  homepage "https://www.gnu.org/software/ddrescue/ddrescue.html"
  url "https://ftpmirror.gnu.org/gnu/ddrescue/ddrescue-1.30.tar.lz"
  mirror "https://ftp.gnu.org/gnu/ddrescue/ddrescue-1.30.tar.lz"
  sha256 "2264622d309d6c87a1cfc19148292b8859a688e9bc02d4702f5cd4f288745542"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "60ca696af3c0b899680e0973670b3df8565e67b3764e1e86437edb5ce21f2b06"
  end

  def install
    system "./configure", "--prefix=#{prefix}",
                          "CXX=#{ENV.cxx}"
    system "make", "install"
  end

  test do
    system bin/"ddrescue", "--force", "--size=64Ki", "/dev/zero", File::NULL
  end
end
