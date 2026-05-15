class Qdbm < Formula
  desc "Library of routines for managing a database"
  homepage "https://dbmx.net/qdbm/"
  url "https://dbmx.net/qdbm/qdbm-1.8.78.tar.gz"
  sha256 "b466fe730d751e4bfc5900d1f37b0fb955f2826ac456e70012785e012cdcb73e"
  license "LGPL-2.1-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?qdbm[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8c9782aa9ac9a0266971342663df668c3207b43560bf629ed3778b50c9f70bed"
  end

  # Last release on 2007-12-22. Succeeded by tokyo-cabinet -> kyoto-cabinet -> tkrzw
  deprecate! date: "2026-04-18", because: :unmaintained
  disable! date: "2027-04-18", because: :unmaintained

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    args = %W[
      --disable-debug
      --prefix=#{prefix}
      --enable-zlib
      --enable-iconv
    ]

    if OS.mac?
      # Does not want to build on Linux
      args << "--enable-bzip"
    else
      ENV.append "LDFLAGS", "-L#{Formula["zlib-ng-compat"].opt_lib}"
    end

    # GCC < 13 with -O2 or higher can cause segmentation faults from loop optimisation bug
    if ENV.compiler.to_s.start_with?("gcc") && DevelopmentTools.gcc_version("gcc") < 13
      ENV.append "CPPFLAGS", "-fno-tree-vrp"
    end

    system "./configure", *args
    if OS.mac?
      system "make", "mac"
      system "make", "install-mac"
    else
      system "make"
      system "make", "install"
    end
  end

  test do
    (testpath/"test.c").write <<~C
      #include <depot.h>
      #include <stdlib.h>
      #include <stdio.h>

      #define NAME     "mike"
      #define NUMBER   "00-12-34-56"
      #define DBNAME   "book"

      int main(void) {
        DEPOT *depot;
        char *val;

        if(!(depot = dpopen(DBNAME, DP_OWRITER | DP_OCREAT, -1))) { return 1; }
        if(!dpput(depot, NAME, -1, NUMBER, -1, DP_DOVER)) { return 1; }
        if(!(val = dpget(depot, NAME, -1, 0, -1, NULL))) { return 1; }

        printf("%s, %s\\n", NAME, val);
        free(val);

        if(!dpclose(depot)) { return 1; }

        return 0;
      }
    C

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lqdbm", "-o", "test"
    assert_equal "mike, 00-12-34-56", shell_output("./test").chomp
  end
end
