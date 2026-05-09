class Jansson < Formula
  desc "C library for encoding, decoding, and manipulating JSON"
  homepage "https://digip.org/jansson/"
  url "https://github.com/akheron/jansson/releases/download/v2.15.0/jansson-2.15.0.tar.gz"
  sha256 "070a629590723228dc3b744ae90e965a569efb9c535b3309b52e80e75d8eb3be"
  license "MIT"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8337be52fd3efb0927dd71db283b10501e4d8a9b6837c970bb6d7987f0ab55ca"
  end

  def install
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <jansson.h>
      #include <assert.h>

      int main()
      {
        json_t *json;
        json_error_t error;
        json = json_loads("\\"foo\\"", JSON_DECODE_ANY, &error);
        assert(json && json_is_string(json));
        json_decref(json);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-ljansson", "-o", "test"
    system "./test"
  end
end
