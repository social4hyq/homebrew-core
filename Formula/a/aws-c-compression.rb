class AwsCCompression < Formula
  desc "C99 implementation of huffman encoding/decoding"
  homepage "https://github.com/awslabs/aws-c-compression"
  url "https://github.com/awslabs/aws-c-compression/archive/refs/tags/v0.3.2.tar.gz"
  sha256 "f93f5a5d8b3fee3a6d97b14ba279efacd4d4016ef9cc7dc4be7d43519ecfbe93"
  license "Apache-2.0"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "92b7cfc4806027b95b386a0aa4ace80b5b7b52d8ef0a00248562e706dbcb6bb3"
  end

  depends_on "cmake" => :build
  depends_on "aws-c-common"

  def install
    system "cmake", "-S", ".", "-B", "build", "-DBUILD_SHARED_LIBS=ON", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <aws/compression/compression.h>
      #include <aws/common/allocator.h>
      #include <assert.h>
      #include <string.h>

      int main(void) {
        struct aws_allocator *allocator = aws_default_allocator();
        aws_compression_library_init(allocator);

        const char *err_name = aws_error_name(AWS_ERROR_COMPRESSION_UNKNOWN_SYMBOL);
        const char *expected = "AWS_ERROR_COMPRESSION_UNKNOWN_SYMBOL";
        assert(strlen(expected) == strlen(err_name));
        for (size_t i = 0; i < strlen(expected); ++i) {
          assert(expected[i] == err_name[i]);
        }

        aws_compression_library_clean_up();
        return 0;
      }
    C
    system ENV.cc, "test.c", "-o", "test", "-L#{lib}", "-laws-c-compression",
                   "-L#{Formula["aws-c-common"].opt_lib}", "-laws-c-common"
    system "./test"
  end
end
