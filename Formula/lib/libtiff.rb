class Libtiff < Formula
  desc "TIFF library and utilities"
  homepage "https://libtiff.gitlab.io/libtiff/"
  url "https://download.osgeo.org/libtiff/tiff-4.7.1.tar.gz"
  mirror "https://fossies.org/linux/misc/tiff-4.7.1.tar.gz"
  sha256 "f698d94f3103da8ca7438d84e0344e453fe0ba3b7486e04c5bf7a9a3fabe9b69"
  license "libtiff"
  revision 1
  compatibility_version 1

  livecheck do
    url "https://download.osgeo.org/libtiff/"
    regex(/href=.*?tiff[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e45bc6ff5fe11f6dab6d238da706d964947b079b73eaae9b7d0047855cbb9010"
  end

  depends_on "jpeg-turbo"
  depends_on "xz"
  depends_on "zstd"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    args = %W[
      --disable-libdeflate
      --disable-webp
      --enable-zstd
      --enable-lzma
      --with-jpeg-include-dir=#{Formula["jpeg-turbo"].opt_include}
      --with-jpeg-lib-dir=#{Formula["jpeg-turbo"].opt_lib}
      --without-x
    ]
    system "./configure", *args, *std_configure_args
    system "make", "install"

    # Avoid rebuilding dependents that hard-code the prefix.
    inreplace lib/"pkgconfig/libtiff-4.pc", prefix, opt_prefix
  end

  test do
    (testpath/"test.c").write <<~C
      #include <tiffio.h>

      int main(int argc, char* argv[])
      {
        TIFF *out = TIFFOpen(argv[1], "w");
        TIFFSetField(out, TIFFTAG_IMAGEWIDTH, (uint32) 10);
        TIFFClose(out);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-ltiff", "-o", "test"
    system "./test", "test.tif"
    assert_match(/ImageWidth.*10/, shell_output("#{bin}/tiffdump test.tif"))
  end
end
