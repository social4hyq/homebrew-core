class ZycoreC < Formula
  desc "Zyan Core Library for C"
  homepage "https://github.com/zyantific/zycore-c"
  url "https://github.com/zyantific/zycore-c/archive/refs/tags/v1.5.2.tar.gz"
  sha256 "943f91eb9ab2a8cc01ab9f8b785e769a273502071e0ee8011cdfcaad93947cec"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "070be2140346c8aea2b1555aa3a4edbcef3b29ea220ad8c923bdf3a62e602e65"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", "-DZYCORE_BUILD_SHARED_LIB=ON", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <stdlib.h>
      #include <Zycore/Status.h>
      #include <Zycore/String.h>

      static ZyanStatus TestDynamic(void) {
        ZyanString string;
        ZYAN_CHECK(ZyanStringInit(&string, 10));

        ZyanStringView view1 = ZYAN_DEFINE_STRING_VIEW("Hello World!");
        ZYAN_CHECK(ZyanStringAppend(&string, &view1));

        const char* cstring;
        ZYAN_CHECK(ZyanStringGetData(&string, &cstring));
        printf("%s", cstring);

        return ZyanStringDestroy(&string);
      }

      int main(void) {
        if (!ZYAN_SUCCESS(TestDynamic())) {
          return EXIT_FAILURE;
        }
        return EXIT_SUCCESS;
      }
    C

    system ENV.cc, "test.c", "-o", "test", "-L#{lib}", "-lZycore"
    assert_equal "Hello World!", shell_output("./test")
  end
end
