class Libunibreak < Formula
  desc "Implementation of the Unicode line- and word-breaking algorithms"
  homepage "https://github.com/adah1972/libunibreak"
  url "https://github.com/adah1972/libunibreak/releases/download/libunibreak_8_0/libunibreak-8.0.tar.gz"
  sha256 "9c4fad6e517338a098373acc9f35579ae2c325e6446666fb9ac2666ba15ceba4"
  license "Zlib"
  compatibility_version 2

  livecheck do
    url :stable
    regex(/v?(\d+(?:[_-]\d+)+)$/i)
    strategy :git do |tags|
      tags.map { |tag| tag[regex, 1]&.tr("_", ".") }
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e43229f5019580255b7dc9ed537e67c41eeb59dd544c5c8cac667a760c68bb0b"
  end

  def install
    system "./configure", *std_configure_args, "--disable-silent-rules"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <unibreakbase.h>
      #include <linebreak.h>
      #include <assert.h>
      #include <stdlib.h>
      #include <string.h>
      int main() {
        static const utf8_t input[] = "test\\nstring \xF0\x9F\x98\x8A test";
        char output[sizeof(input) - 1];
        static const char expected[] = {
          2, 2, 2, 2, 0,
          2, 2, 2, 2, 2, 2, 1,
          3, 3, 3, 2, 1,
          2, 2, 2, 4
        };

        assert(sizeof(output) == sizeof(expected));

        init_linebreak();
        set_linebreaks_utf8(input, sizeof(output), NULL, output);

        return memcmp(output, expected, sizeof(output)) != 0;
      }
    C
    system ENV.cc, "-o", "test", "test.c", "-I#{include}",
                   "-L#{lib}", "-lunibreak"
    system "./test"
  end
end
