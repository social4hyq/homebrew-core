class Rlog < Formula
  desc "Flexible message logging facility for C++"
  homepage "https://github.com/vgough/rlog"
  url "https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/rlog/rlog-1.4.tar.gz"
  sha256 "a938eeedeb4d56f1343dc5561bc09ae70b24e8f70d07a6f8d4b6eed32e783f79"
  license "LGPL-2.1-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "47016ffb21d1de8231b15d6b9008d099d734086cd03b1da95c6b62604ca4847c"
  end

  patch :DATA

  def install
    # Fix flat namespace usage
    inreplace "configure", "${wl}-flat_namespace ${wl}-undefined ${wl}suppress", "${wl}-undefined ${wl}dynamic_lookup"

    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <stdio.h>
      #include <unistd.h>
      #include <rlog/rlog.h>
      #include <rlog/RLogChannel.h>
      #include <rlog/RLogNode.h>
      #include <rlog/StdioNode.h>
      int main(int argc, char **argv)
      {
          rlog::RLogInit(argc, argv);
          rlog::StdioNode stdLog(STDOUT_FILENO);
          stdLog.subscribeTo(rlog::GetGlobalChannel(""));
          const char *name = "Dave";
          rDebug("num = %i", 299792458);
          int ans = 6 * 9;
          if (ans != 42) rWarning("ans = %i, expecting 42", ans);
          rError("I'm sorry %s, I can't do that.", name);
      }
    CPP

    expected_outputs = [
      "(test.cpp:13) num = 299792458",
      "(test.cpp:15) ans = 54, expecting 42",
      "(test.cpp:16) I'm sorry Dave, I can't do that.",
    ]

    system ENV.cxx, "-I#{include}", "-L#{lib}", "test.cpp", "-lrlog", "-o", "test"
    output = shell_output("./test")
    expected_outputs.each do |expected|
      assert_match expected, output
    end
  end
end

# This patch solves an OSX build issue, should not be necessary for the next release according to
# https://code.google.com/p/rlog/issues/detail?id=7
__END__
--- orig/rlog/common.h.in	2008-06-14 20:10:13.000000000 -0700
+++ new/rlog/common.h.in	2009-05-18 16:05:04.000000000 -0700
@@ -52,7 +52,12 @@

 # define PRINTF(FMT,X) __attribute__ (( __format__ ( __printf__, FMT, X)))
 # define HAVE_PRINTF_ATTR 1
+
+#ifdef __APPLE__
+# define RLOG_SECTION __attribute__ (( section("__DATA, RLOG_DATA") ))
+#else
 # define RLOG_SECTION __attribute__ (( section("RLOG_DATA") ))
+#endif

 #if __GNUC__ >= 3
 # define expect(foo, bar) __builtin_expect((foo),bar)
