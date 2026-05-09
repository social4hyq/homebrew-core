class Llhttp < Formula
  desc "Port of http_parser to llparse"
  homepage "https://llhttp.org/"
  url "https://github.com/nodejs/llhttp/archive/refs/tags/release/v9.4.1.tar.gz"
  sha256 "86a8c16759fdcc7aa2c9841fbe8ba2e77ea98be7d5d45615f2604776d0ff78c7"
  license "MIT"
  compatibility_version 2

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3f22ec69f661b117072b59a36e8e915c858e4fdb123c0b132d1778473d94a8f1"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~'C'
      #include <stdio.h>
      #include <string.h>
      #include <llhttp.h>

      int handle_on_message_complete(llhttp_t* parser) {
        fprintf(stdout, "Message completed!\n");
        return 0;
      }

      int main(void) {
        llhttp_t parser;
        llhttp_settings_t settings;
        llhttp_settings_init(&settings);
        settings.on_message_complete = handle_on_message_complete;
        llhttp_init(&parser, HTTP_BOTH, &settings);

        const char* request = "GET / HTTP/1.1\r\n\r\n";
        int request_len = strlen(request);
        enum llhttp_errno err = llhttp_execute(&parser, request, request_len);

        if (err == HPE_OK) {
          fprintf(stdout, "Successfully parsed!\n");
          return 0;
        } else {
          fprintf(stderr, "Parse error: %s %s\n", llhttp_errno_name(err), llhttp_get_error_reason(&parser));
          return 1;
        }
      }
    C
    system ENV.cc, "test.c", "-o", "test", "-L#{lib}", "-lllhttp"
    assert_equal "Message completed!\nSuccessfully parsed!\n", shell_output("./test")
  end
end
