class Libchardet < Formula
  desc "Mozilla's Universal Charset Detector C/C++ API"
  homepage "https://github.com/Joungkyun/libchardet"
  url "https://github.com/Joungkyun/libchardet/archive/refs/tags/1.0.6.tar.gz"
  sha256 "425f3fa9e7afa0ebc3f4e3572637fb87bd6541e2716ad2c18f175995eb2021f0"
  license any_of: ["MPL-1.1", "LGPL-2.1-only"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d2dc60218bc7d731e7167caddfc3c9c0f33766264321ad2a9ed8834a82bb074d"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :test

  def install
    system "autoreconf", "--install"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <assert.h>
      #include <chardet.h>
      #include <string.h>

      int main(void) {
        DetectObj *o;
        char *str = "안녕하세요";

        if ((o = detect_obj_init()) == NULL)
          return 1;

        switch (detect_r(str, strlen(str), &o)) {
          case CHARDET_NULL_OBJECT:
          case CHARDET_OUT_OF_MEMORY:
            return 1;

          default:
            assert(strcmp(o->encoding, "UTF-8") == 0);
            return 0;
        }
      }
    C
    flags = shell_output("#{Formula["pkgconf"].opt_bin}/pkgconf --cflags --libs chardet").strip.split
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"

    assert_match version.to_s, (lib/"pkgconfig/chardet.pc").read
  end
end
