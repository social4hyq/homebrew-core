class Isl < Formula
  # NOTE: Always use tarball instead of git tag for stable version.
  #
  # Currently isl detects its version using source code directory name
  # and update isl_version() function accordingly.  All other names will
  # result in isl_version() function returning "UNKNOWN" and hence break
  # package detection.
  desc "Integer Set Library for the polyhedral model"
  homepage "https://libisl.sourceforge.io/"
  url "https://libisl.sourceforge.io/isl-0.28.tar.xz"
  sha256 "3dc31b8e1b18329e42d5dfbf84dd55e15c59b61569a2ab246f61497d9592f727"
  license "MIT"

  livecheck do
    url :homepage
    regex(/href=.*?isl[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1290acba646a81c5ec65865c7da706117697347b28844de530ad3a3de67a0b81"
  end

  head do
    url "https://repo.or.cz/isl.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "gmp"

  def install
    # The OHOS C library only declares ffs/ffsl in strings.h when _GNU_SOURCE
    # (or _BSD_SOURCE) is defined, which makes configure abort with
    # "No ffs implementation found".
    ENV.append "CPPFLAGS", "-D_GNU_SOURCE" if OS.ohos?

    system "./autogen.sh" if build.head?
    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}",
                          "--with-gmp=system",
                          "--with-gmp-prefix=#{formula_opt_prefix("gmp")}"
    system "make"
    system "make", "install"
    (share/"gdb/auto-load").install Dir["#{lib}/*-gdb.py"]
  end

  test do
    (testpath/"test.c").write <<~C
      #include <isl/ctx.h>

      int main()
      {
        isl_ctx* ctx = isl_ctx_alloc();
        isl_ctx_free(ctx);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lisl", "-o", "test"
    system "./test"
  end
end
