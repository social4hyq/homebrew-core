class Libfastjson < Formula
  desc "Fast json library for C"
  homepage "https://github.com/rsyslog/libfastjson"
  url "https://download.rsyslog.com/libfastjson/libfastjson-1.2609.0.tar.gz"
  sha256 "7cd6f78c1c07f4140f6976a9a0e0048bcaa7292329c6ac2c0e070383d83d8edd"
  license "BSD-2-Clause"

  livecheck do
    url "https://download.rsyslog.com/libfastjson/"
    regex(/href=.*?libfastjson[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d4e1f5aea8b1f4bed47b9b0f1987336f2badde749c9a998b88fd4d93a855bd5c"
  end

  def install
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <libfastjson/json.h>

      int main() {
        char json_string[]  = "{\\"message\\":\\"Hello world!\\"}";
        struct fjson_object* root;
        struct fjson_object* message;

        root = fjson_tokener_parse(json_string);
        if (root == NULL) {
          fprintf(stderr, "Parsing failed\\n");
          return 1;
        }

        if (fjson_object_object_get_ex(root, "message", &message)) {
          printf("%s\\n", fjson_object_get_string(message));
        } else {
          fprintf(stderr, "Failed to get 'message' field\\n");
        }

        fjson_object_put(root);

        return 0;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lfastjson", "-o", "test"
    system "./test"
  end
end
