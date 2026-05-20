class Argtable3 < Formula
  desc "ANSI C library for parsing GNU-style command-line options"
  homepage "https://www.argtable.org"
  url "https://github.com/argtable/argtable3/releases/download/v3.3.1/argtable-v3.3.1.tar.gz"
  sha256 "c08bca4b88ddb9234726b75455b3b1670d7c864d8daf198eaa7a3b4d41addf2c"
  license "BSD-3-Clause"
  revision 1
  head "https://github.com/argtable/argtable3.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c1e5c7e49a988bd4941384c7fe8c65c6f46523481b300c358b4980acf9a06228"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", "-DBUILD_SHARED_LIBS=ON", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include "argtable3.h"
      #include <assert.h>
      #include <stdio.h>

      int main (int argc, char **argv) {
        struct arg_lit *all = arg_lit0 ("a", "all", "show all");
        struct arg_end *end = arg_end(20);
        void *argtable[] = {all, end};

        assert (arg_nullcheck(argtable) == 0);
        if (arg_parse(argc, argv, argtable) == 0) {
          if (all->count) puts ("Received option");
        } else {
          puts ("Invalid option");
        }
      }
    C

    system ENV.cc, "test.c", "-L#{lib}", "-I#{include}", "-largtable3",
                   "-o", "test"
    assert_match "Received option", shell_output("./test -a")
    assert_match "Received option", shell_output("./test --all")
    assert_match "Invalid option", shell_output("./test -t")
  end
end
