class Libscfg < Formula
  desc "C library for scfg"
  homepage "https://codeberg.org/emersion/libscfg"
  url "https://ftp.debian.org/debian/pool/main/libs/libscfg/libscfg_0.2.0.orig.tar.gz"
  sha256 "11df0bf3654214ce51c2965819ce741409aa6b5403728669c5a6b8ab55c2e5d3"
  license "MIT"
  head "https://codeberg.org/emersion/libscfg.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "58211ff027c6258934460e26aaec4fd76c8ccec7cabbf75465663cb1e1e817f4"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.cfg").write <<~EOS
      key1 = value1
      key2 = value2
    EOS

    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <stdlib.h>
      #include "scfg.h"

      int main() {
        const char* testFilePath = "test.cfg";
        struct scfg_block block = {0};

        int loadResult = scfg_load_file(&block, testFilePath);
        printf("Successfully loaded '%s'.\\n", testFilePath);

        for (size_t i = 0; i < block.directives_len; i++) {
          printf("Directive: %s\\n", block.directives[i].name);
          for (size_t j = 0; j < block.directives[i].params_len; j++) {
            printf("  Parameter: %s\\n", block.directives[i].params[j]);
          }
        }

        scfg_block_finish(&block);

        return 0;
      }
    C

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lscfg", "-o", "test"
    assert_match "Successfully loaded 'test.cfg'", shell_output("./test")
  end
end
