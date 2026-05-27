class Jerryscript < Formula
  desc "Ultra-lightweight JavaScript engine for the Internet of Things"
  homepage "https://jerryscript.net"
  url "https://github.com/jerryscript-project/jerryscript/archive/refs/tags/v3.0.0.tar.gz"
  sha256 "4d586d922ba575d95482693a45169ebe6cb539c4b5a0d256a6651a39e47bf0fc"
  license "Apache-2.0"
  head "https://github.com/jerryscript-project/jerryscript.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b2f7a424cf15e6797f4b300352e52b21568e96e9f3fe90297566827e49be11d4"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :test

  # rpath patch, upstream pr ref, https://github.com/jerryscript-project/jerryscript/pull/5204
  patch do
    url "https://github.com/jerryscript-project/jerryscript/commit/e8948ac3f34079ac6f3d6f47f8998b82f16b1621.patch?full_index=1"
    sha256 "ebce75941e1f34118fed14e317500b0ab69f48182ba9cce8635e9f62fe9aa4d1"
  end

  def install
    args = %w[
      -DCMAKE_BUILD_TYPE=MinSizeRel
      -DJERRY_CMDLINE=ON
      -DBUILD_SHARED_LIBS=ON
    ]

    system "cmake", "-S", ".", "-B", ".", *args, *std_cmake_args
    system "cmake", "--build", "."
    system "cmake", "--install", "."
  end

  test do
    (testpath/"test.js").write "print('Hello, Homebrew!');"
    assert_equal "Hello, Homebrew!", shell_output("#{bin}/jerry test.js").strip

    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include "jerryscript.h"

      int main (void)
      {
        const jerry_char_t script[] = "1 + 2";
        const jerry_length_t script_size = sizeof(script) - 1;

        jerry_init(JERRY_INIT_EMPTY);
        jerry_value_t eval_ret = jerry_eval(script, script_size, JERRY_PARSE_NO_OPTS);
        bool run_ok = !jerry_value_is_error(eval_ret);
        if (run_ok) {
          printf("1 + 2 = %d\\n", (int) jerry_value_as_number(eval_ret));
        }

        jerry_value_free(eval_ret);
        jerry_cleanup();
        return (run_ok ? 0 : 1);
      }
    C

    pkg_config_flags = shell_output("pkgconf --cflags --libs libjerry-core libjerry-port libjerry-ext").chomp.split
    system ENV.cc, "test.c", "-o", "test", *pkg_config_flags
    assert_equal "1 + 2 = 3", shell_output("./test").strip, "JerryScript can add number"
  end
end
