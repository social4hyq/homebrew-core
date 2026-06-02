class Splint < Formula
  desc "Secure Programming Lint"
  homepage "https://splint.org/"
  license "GPL-2.0-or-later"

  stable do
    url "https://splint.org/downloads/splint-3.1.2.src.tgz"
    mirror "https://mirrorservice.org/sites/distfiles.macports.org/splint/splint-3.1.2.src.tgz"
    sha256 "c78db643df663313e3fa9d565118391825dd937617819c6efc7966cdf444fb0a"

    # fix compiling error of osd.c
    patch :DATA
  end

  livecheck do
    url :head
    regex(/^(?:splint[._-])?v?(\d+(?:[._]\d+)+)$/i)
    strategy :git do |tags, regex|
      tags.map { |tag| tag[regex, 1]&.tr("_", ".") }
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d8dacfc9e36a92d7a67cb0d82d5666da4ff80f8670acf99d0a2461f28bb98122"
  end

  head do
    url "https://github.com/splintchecker/splint.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "bison" => :build
    depends_on "flex"
  end

  uses_from_macos "flex"

  def install
    ENV.deparallelize # build is not parallel-safe

    if build.head?
      ENV.append "CFLAGS", "-std=gnu99"
      system "./bootstrap"
    else
      args = ["--mandir=#{man}"]
      args << "LEXLIB=#{Formula["flex"].opt_lib}/libfl.so" if OS.linux?
      # Help old config scripts identify arm64 linux
      args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm64?
    end

    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    path = testpath/"test.c"
    path.write <<~C
      #include <stdio.h>
      int main()
      {
          char c;
          printf("%c", c);
          return 0;
      }
    C

    output = shell_output("#{bin}/splint #{path} 2>&1", 1)
    assert_match(/5:18:\s+Variable c used before definition/, output)
  end
end


__END__
diff --git a/src/osd.c b/src/osd.c
index ebe214a..4ba81d5 100644
--- a/src/osd.c
+++ b/src/osd.c
@@ -516,7 +516,7 @@ osd_getPid ()
 # if defined (WIN32) || defined (OS2) && defined (__IBMC__)
   int pid = _getpid ();
 # else
-  __pid_t pid = getpid ();
+  pid_t pid = getpid ();
 # endif

   return (int) pid;
