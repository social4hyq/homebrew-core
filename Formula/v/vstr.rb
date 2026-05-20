class Vstr < Formula
  desc "C string library"
  homepage "http://www.and.org/vstr/"
  url "https://distfiles.macports.org/vstr/vstr-1.0.15.tar.bz2"
  mirror "http://www.and.org/vstr/1.0.15/vstr-1.0.15.tar.bz2"
  sha256 "d33bcdd48504ddd21c0d53e4c2ac187ff6f0190d04305e5fe32f685cee6db640"
  license "LGPL-2.1-or-later"

  livecheck do
    url "http://www.and.org/vstr/latest/"
    regex(/href=.*?vstr[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "528cca71b65b3505ae163322be2f24e6b35dfdda5c33aff37ea92c9a2e36430e"
  end

  depends_on "pkgconf" => :build

  # Fix flat namespace usage on macOS.
  patch :DATA

  def install
    ENV.append "CFLAGS", "--std=gnu89"
    ENV["ac_cv_func_stat64"] = "no" if OS.mac? && Hardware::CPU.arm?

    args = ["--mandir=#{man}"]
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      // based on http://www.and.org/vstr/examples/ex_hello_world.c
      #define VSTR_COMPILE_INCLUDE 1
      #include <vstr.h>
      #include <errno.h>
      #include <err.h>
      #include <unistd.h>

      int main(void) {
        Vstr_base *s1 = NULL;

        if (!vstr_init())
          err(EXIT_FAILURE, "init");

        if (!(s1 = vstr_dup_cstr_buf(NULL, "Hello Homebrew\\n")))
          err(EXIT_FAILURE, "Create string");

        while (s1->len)
          if (!vstr_sc_write_fd(s1, 1, s1->len, STDOUT_FILENO, NULL)) {
            if ((errno != EAGAIN) && (errno != EINTR))
              err(EXIT_FAILURE, "write");
          }

        vstr_free_base(s1);
        vstr_exit();
      }
    C

    system ENV.cc, "test.c", "-L#{lib}", "-lvstr", "-o", "test"
    system "./test"
  end
end

__END__
diff --git a/configure b/configure
index 84b6b1b..ffa2faf 100755
--- a/configure
+++ b/configure
@@ -8313,7 +8313,7 @@ if test -z "$aix_libpath"; then aix_libpath="/usr/lib:/lib"; fi
          ;;
        *) # Darwin 1.3 on
          if test -z ${MACOSX_DEPLOYMENT_TARGET} ; then
-           allow_undefined_flag='${wl}-flat_namespace ${wl}-undefined ${wl}suppress'
+           allow_undefined_flag='${wl}-undefined ${wl}dynamic_lookup'
          else
            case ${MACOSX_DEPLOYMENT_TARGET} in
              10.[012])
