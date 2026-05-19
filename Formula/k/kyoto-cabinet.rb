class KyotoCabinet < Formula
  desc "Library of routines for managing a database"
  homepage "https://dbmx.net/kyotocabinet/"
  url "https://dbmx.net/kyotocabinet/pkg/kyotocabinet-1.2.80.tar.gz"
  sha256 "4c85d736668d82920bfdbdb92ac3d66b7db1108f09581a769dd9160a02def349"
  license "GPL-3.0-or-later"

  livecheck do
    url "https://dbmx.net/kyotocabinet/pkg/"
    regex(/href=.*?kyotocabinet[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1df31bd92051785efec606308f053e9a693ed448dc797e280c097379c9ecf1d2"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  patch :DATA

  def install
    if OS.linux?
      ENV.append_to_cflags "-I#{Formula["zlib-ng-compat"].opt_include}"
      ENV.append "LDFLAGS", "-L#{Formula["zlib-ng-compat"].opt_lib}"
    end
    ENV.cxx11
    system "./configure", *std_configure_args
    system "make" # Separate steps required
    system "make", "install"
  end

  test do
    # https://dbmx.net/kyotocabinet/spex.html#tutorial_kchashmgr
    system bin/"kchashmgr", "create", "staffs.kch"
    system bin/"kchashmgr", "set", "staffs.kch", "1001", "George Washington"
    system bin/"kchashmgr", "set", "staffs.kch", "1002", "John Adams"
    system bin/"kchashmgr", "set", "staffs.kch", "1003", "Thomas Jefferson"
    system bin/"kchashmgr", "set", "staffs.kch", "1004", "James Madison"
    assert_equal <<~EOS, shell_output("#{bin}/kchashmgr list -pv staffs.kch")
      1001\tGeorge Washington
      1002\tJohn Adams
      1003\tThomas Jefferson
      1004\tJames Madison
    EOS
  end
end


__END__
--- a/kccommon.h  2013-11-08 09:27:37.000000000 -0500
+++ b/kccommon.h  2013-11-08 09:27:47.000000000 -0500
@@ -82,7 +82,7 @@
 using ::snprintf;
 }

-#if __cplusplus > 199711L || defined(__GXX_EXPERIMENTAL_CXX0X__) || defined(_MSC_VER)
+#if __cplusplus > 199711L || defined(__GXX_EXPERIMENTAL_CXX0X__) || defined(_MSC_VER) || defined(_LIBCPP_VERSION)

 #include <unordered_map>
 #include <unordered_set>
