class Minizip < Formula
  desc "C library for zip/unzip via zLib"
  homepage "https://www.winimage.com/zLibDll/minizip.html"
  url "https://zlib.net/zlib-1.3.2.tar.gz"
  sha256 "bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16"
  license "Zlib"
  revision 2
  compatibility_version 1

  livecheck do
    formula "zlib"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b854a533547e4f0bff45a981cca4aafff1221df944196456ca7ddb1083ff9f47"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  uses_from_macos "unzip" => :test
  uses_from_macos "zip" => :test

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    cd "contrib/minizip" do
      system "autoreconf", "--force", "--install", "--verbose"
      system "./configure", *std_configure_args
      system "make", "install"
      # `ints.h` is required by `ioapi.h` but is not installed in zlib 1.3.2.
      # Remove once upstream includes it in releases:
      # https://github.com/madler/zlib/pull/1165
      (include/"minizip").install "ints.h"
    end
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <stdlib.h>
      #include <stdint.h>
      #include <minizip/unzip.h>

      static const char *zipname = "test.zip";

      int main(int argc, char **argv)
      {
          unzFile uzfile = unzOpen64(zipname);
          if (uzfile == NULL) {
              printf("Could not open %s for unzipping\\n", zipname);
              return 1;
          }

          do {
              unz_file_info64 finfo;
              char zfilename[256];
              char *string_method;
              int ret = unzGetCurrentFileInfo64(uzfile, &finfo, zfilename, sizeof(zfilename), NULL, 0, NULL, 0);
              if (ret != UNZ_OK) return ret;
              if (finfo.compression_method == 0) string_method = "Stored";
              else if (finfo.compression_method == Z_DEFLATED) {
                  uint16_t level = (uint16_t)((finfo.flag & 0x6) / 2);
                  if (level == 0)
                      string_method = "Defl:N";
                  else if (level == 1)
                      string_method = "Defl:X";
                  else if ((level == 2) || (level == 3))
                      string_method = "Defl:F";
                  else
                      string_method = "Unkn. ";
              } else if (finfo.compression_method == Z_BZIP2ED) string_method = "BZip2 ";
              else string_method = "Unkn. ";
              printf("%llu %s %llu %8.8lx %s\\n", finfo.uncompressed_size, string_method, finfo.compressed_size, finfo.crc, zfilename);
          } while (unzGoToNextFile(uzfile) != UNZ_END_OF_LIST_OF_FILE);
          return 0;
      }
    C

    system "zip", "-r", testpath/"test.zip", prefix
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lminizip", "-o", "test"

    test_results = shell_output(testpath/"test").lines.map(&:split)

    unzip_listing = shell_output("unzip -lv #{testpath}/test.zip").lines
    unzip_listing = unzip_listing.slice(3..(unzip_listing.length - 3))
    unzip_indices_to_keep = [0, 1, 2, 6, 7]
    unzip_results = unzip_listing.map do |item|
      item.split.select.with_index { |_, idx| unzip_indices_to_keep.include?(idx) }
    end

    assert_equal unzip_results, test_results
  end
end
