class Xlsxio < Formula
  desc "C library for reading values from and writing values to .xlsx files"
  homepage "https://github.com/brechtsanders/xlsxio"
  url "https://github.com/brechtsanders/xlsxio/archive/refs/tags/0.2.36.tar.gz"
  sha256 "80d3df95a7a108a41f83f0ce4c6706873fd2afafd92424fcccea475a8acbd044"
  license "MIT"
  revision 1
  head "https://github.com/brechtsanders/xlsxio.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ec3834a0bbc3b3879870373fe59d6bdb69f8695d2645c27e9e7d5abb952cdf64"
  end

  depends_on "libzip"
  uses_from_macos "expat"

  def install
    system "make", "install", "PREFIX=#{prefix}", "V=1", "WITH_LIBZIP=1"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdlib.h>
      #include <stdio.h>
      #include <unistd.h>
      #include <xlsxio_read.h>
      #include <xlsxio_write.h>

      int main() {
        xlsxiowriter handle;
        if ((handle = xlsxiowrite_open("myexcel.xlsx", "MySheet")) == NULL) {
          return 1;
        }
        return xlsxiowrite_close(handle);
      }
    C

    system ENV.cc, "test.c", "-L#{lib}", "-I#{include}", "-lxlsxio_read", "-lxlsxio_write", "-o", "test"
    system "./test"
    assert_path_exists testpath/"myexcel.xlsx", "Failed to create xlsx file"
  end
end
