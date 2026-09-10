class Libfixposix < Formula
  desc "Thin wrapper over POSIX syscalls"
  homepage "https://github.com/sionescu/libfixposix"
  url "https://github.com/sionescu/libfixposix/archive/refs/tags/v0.5.1.tar.gz"
  sha256 "5d9d3d321d4c7302040389c43f966a70d180abb58d1d7df370f39e0d402d50d4"
  license "BSL-1.0"
  revision 1
  head "https://github.com/sionescu/libfixposix.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d25a92f0cd6dc1171530a2f49663a761568cf8c8f90501a596a3054bdbaf3ab2"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"mxstemp.c").write <<~C
      #include <stdio.h>

      #include <lfp.h>

      int main(void)
      {
          fd_set rset, wset, eset;

          lfp_fd_zero(&rset);
          lfp_fd_zero(&wset);
          lfp_fd_zero(&eset);

          for(unsigned i = 0; i < FD_SETSIZE; i++) {
              if(lfp_fd_isset(i, &rset)) {
                  printf("%d ", i);
              }
          }

          return 0;
      }
    C
    system ENV.cc, "mxstemp.c", lib/shared_library("libfixposix"), "-o", "mxstemp"
    system "./mxstemp"
  end
end
