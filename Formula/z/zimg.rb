class Zimg < Formula
  desc "Scaling, colorspace conversion, and dithering library"
  homepage "https://github.com/sekrit-twc/zimg"
  url "https://github.com/sekrit-twc/zimg/archive/refs/tags/release-3.0.6.tar.gz"
  sha256 "be89390f13a5c9b2388ce0f44a5e89364a20c1c57ce46d382b1fcc3967057577"
  license "WTFPL"
  compatibility_version 1
  head "https://github.com/sekrit-twc/zimg.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e49dbde5bf0fda437028ec8b767ef7addec24cfbc98c2f300dc86cf6e57442f3"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  def install
    if OS.linux?
      # Fix libzimg.so.2: __eqtf2: symbol not found error on OHOS.
      # 128-bit float software routines (__eqtf2 etc.) from compiler-rt
      # are not pulled in by the linker automatically on OHOS; force them.
      builtins = Utils.safe_popen_read(ENV.cc, "-print-file-name=libclang_rt.builtins.a").strip
      ENV.append "LDFLAGS", "-Wl,--whole-archive #{builtins} -Wl,--no-whole-archive"
      ENV.append "LDFLAGS", "-Wl,--exclude-libs=#{File.basename(builtins)}"
    end

    system "./autogen.sh"
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <assert.h>
      #include <zimg.h>

      int main()
      {
        zimg_image_format format;
        zimg_image_format_default(&format, ZIMG_API_VERSION);
        assert(ZIMG_MATRIX_UNSPECIFIED == format.matrix_coefficients);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lzimg", "-o", "test"
    system "./test"
  end
end
