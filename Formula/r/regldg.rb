class Regldg < Formula
  desc "Regular expression grammar language dictionary generator"
  homepage "https://regldg.com/"
  url "https://github.com/PatrickCronin/regldg/releases/download/v1.0.1/regldg-1.0.1.tar.gz"
  sha256 "f5f401c645a94d4c737cefa2bbcb62f23407d25868327902b9c93b501335dc99"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "82e8e30ed31e50a37f6511915dd85712689141279fe0eb5477efea95055c99f0"
  end

  # Workaround for newer Clang
  patch :DATA

  def install
    # Temporary Homebrew-specific work around for linker flag ordering problem in Ubuntu 16.04.
    # Remove after migration to 18.04.
    inreplace "Makefile", "-o regldg", "-o regldg -lm" unless OS.mac?
    system "make"
    bin.install "regldg"
  end

  test do
    system bin/"regldg", "test"
  end
end

__END__
diff --git a/Makefile b/Makefile
index 5e18193..6dee9ae 100755
--- a/Makefile
+++ b/Makefile
@@ -1,7 +1,7 @@
 # Makefile
 # Project building instructions.

-COMPILE=cc -O3 -Wall -g -c
+COMPILE=cc -O3 -Wall -Wno-int-conversion -g -c
 LINK=gcc -O3 -Wall -g -lm

 all: alt.o altlist.o build_structs.o char_set.o data.o debug.o \
