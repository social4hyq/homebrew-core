class Merve < Formula
  desc "C++ lexer for extracting named exports from CommonJS modules"
  homepage "https://github.com/nodejs/merve"
  url "https://github.com/nodejs/merve/archive/refs/tags/v1.2.2.tar.gz"
  sha256 "8f19c2132447b9113545ffd399cb2bc1e61c6166743921b04883f8e1d778d69e"
  license "Apache-2.0"
  revision 2

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1bc860f7d426b8c09fe1cf880a7c659732e0296e999c42f648f3b2cb5e7ede65"
  end

  depends_on "cmake" => :build
  depends_on "simdutf"

  def install
    args = %w[
      -DMERVE_TESTING=OFF
      -DMERVE_USE_SIMDUTF=ON
      -DBUILD_SHARED_LIBS=ON
      -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON
    ]
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args, *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test-merv.c").write <<~'C'
      #include "merve_c.h"
      #include <stdio.h>
      #include <string.h>

      int main(void) {
        const char *source = "exports.foo = 1;\nexports.bar = 2;\n";
        merve_analysis result = merve_parse_commonjs(source, strlen(source), NULL);
        merve_string export_name;

        if (!result || !merve_is_valid(result)) return 1;

        export_name = merve_get_export_name(result, 1);
        printf("%zu %.*s %u\n",
               merve_get_exports_count(result),
               (int) export_name.length, export_name.data,
               merve_get_export_line(result, 1));
        merve_free(result);
        return 0;
      }
    C
    system ENV.cc, "test-merv.c", "-I#{include}", "-L#{lib}", "-lmerve", "-o", "test-merv"
    assert_equal "2 bar 2\n", shell_output("./test-merv")
  end
end
