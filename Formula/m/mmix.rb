class Mmix < Formula
  desc "64-bit RISC architecture designed by Donald Knuth"
  homepage "https://mmix.cs.hm.edu/"
  url "https://mmix.cs.hm.edu/src/mmix-20160804.tgz"
  sha256 "fad8e64fddf2d75cbcd5080616b47e11a2d292a428cdb0c12e579be680ecdee9"
  license "MMIXware"

  livecheck do
    url "https://mmix.cs.hm.edu/src/"
    regex(/href=.*?mmix[._-]v?(\d+(?:\.\d+)*)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a1fc4bbffae4e4872066ebc07d8f424b60e48801715221ca62de94750dbf2cce"
  end

  depends_on "cweb" => :build

  # fix implicit int build error
  # upstream patch ref, https://gitlab.lrz.de/mmix/mmixware/-/commit/c02e7081d033895dfaeb8154ad9bd6f5893487ea
  patch :DATA

  # fix duplicate declaration of buffer
  patch do
    url "https://gitlab.lrz.de/mmix/mmixware/-/commit/2eddd633bc98fd320e317bbcd6c98399250e68ec.diff"
    sha256 "512fc7d27b974bf5a58781464d4dba1c2147142ba749a2eb17c1a7b358ef8db9"
  end

  def install
    ENV.deparallelize
    system "make", "all"
    bin.install "mmix", "mmixal", "mmmix", "mmotype"
  end

  test do
    (testpath/"hello.mms").write <<~EOS
            LOC  Data_Segment
            GREG @
      txt   BYTE "Hello world!",0

            LOC #100

      Main  LDA $255,txt
            TRAP 0,Fputs,StdOut
            TRAP 0,Fputs,StdErr
            TRAP 0,Halt,0
    EOS
    system bin/"mmixal", "hello.mms"
    assert_equal "Hello world!", shell_output("#{bin}/mmix hello.mmo")
  end
end

__END__
diff --git a/abstime.w b/abstime.w
index 50d6aa9f7585afae69ff22ee9b58a919c2c1db97..6605ba1071995e70b3e435009b52f5f3c2f7ea72 100644
--- a/abstime.w
+++ b/abstime.w
@@ -18,7 +18,7 @@ hold more than 32 bits.
 #include <stdio.h>
 #include <time.h>
 @#
-main()
+int main()
 {
   printf("#define ABSTIME %ld\n",time(NULL));
   return 0;
