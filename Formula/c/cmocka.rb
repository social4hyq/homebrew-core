class Cmocka < Formula
  desc "Unit testing framework for C"
  homepage "https://cmocka.org/"
  url "https://cmocka.org/files/2.0/cmocka-2.0.2.tar.xz"
  sha256 "39f92f366bdf3f1a02af4da75b4a5c52df6c9f7e736c7d65de13283f9f0ef416"
  license "Apache-2.0"
  head "https://git.cryptomilk.org/projects/cmocka.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e2c2218dbb45c75987b9fed1a6d7fed61f513bec4044a3b2389e6f52605ab831"
  end

  depends_on "cmake" => :build

  def install
    args = %w[
      -DWITH_STATIC_LIB=ON
      -DWITH_CMOCKERY_SUPPORT=ON
      -DUNIT_TESTING=ON
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdarg.h>
      #include <stddef.h>
      #include <setjmp.h>
      #include <cmocka.h>

      static void null_test_success(void **state) {
        (void) state; /* unused */
      }

      int main(void) {
        const struct CMUnitTest tests[] = {
            cmocka_unit_test(null_test_success),
        };
        return cmocka_run_group_tests(tests, NULL, NULL);
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lcmocka", "-o", "test"
    system "./test"
  end
end
