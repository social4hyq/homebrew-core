class Jemalloc < Formula
  desc "Implementation of malloc emphasizing fragmentation avoidance"
  homepage "https://jemalloc.net/"
  url "https://github.com/jemalloc/jemalloc/releases/download/5.3.0/jemalloc-5.3.0.tar.bz2"
  sha256 "2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa"
  license "BSD-2-Clause"

  head do
    url "https://github.com/jemalloc/jemalloc.git", branch: "dev"

    depends_on "autoconf" => :build
    depends_on "docbook-xsl" => :build
  end

  def install
    args = %W[
      --disable-debug
      --prefix=#{prefix}
      --with-jemalloc-prefix=je_
      --disable-cxx
    ]
    if build.head?
      args << "--with-xslroot=#{Formula["docbook-xsl"].opt_prefix}/docbook-xsl"
      system "./autogen.sh", *args
      system "make", "dist"
    else
      system "./configure", *args
    end

    system "make"
    # Do not run checks with Xcode 15, they fail because of
    # overly eager optimization in the new compiler:
    # https://github.com/jemalloc/jemalloc/issues/2540
    # Reported to Apple as FB13209585
    system "make", "check" if DevelopmentTools.clang_build_version < 1500
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdlib.h>
      #include <jemalloc/jemalloc.h>

      int main(void) {

        for (size_t i = 0; i < 1000; i++) {
            // Leak some memory
            je_malloc(i * 100);
        }

        // Dump allocator statistics to stderr
        je_malloc_stats_print(NULL, NULL, NULL);
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-ljemalloc", "-o", "test"
    system "./test"
  end
end
