class Cgoban < Formula
  desc "Go-related services"
  homepage "https://cgoban1.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/cgoban1/cgoban1/1.9.14/cgoban-1.9.14.tar.gz"
  sha256 "3b8a6fc0e989bf977fcd9a65a367aa18e34c6e25800e78dd8f0063fa549c9b62"
  license "GPL-2.0-or-later"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fd13132adc2b3b0a63bbfa014958dfdb00f8a345d7d9e73fe175981260a5afe2"
  end

  depends_on "libice"
  depends_on "libsm"
  depends_on "libx11"

  def install
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--mandir=#{man}",
                          "--with-x",
                          "--x-includes=#{Formula["libx11"].opt_include}",
                          "--x-libraries=#{Formula["libx11"].opt_lib}"
    system "make", "install"
  end

  test do
    assert_match "version #{version}", shell_output("#{bin}/cgoban --version")
  end
end
