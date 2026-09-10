class Libunwind < Formula
  desc "C API for determining the call-chain of a program"
  homepage "https://www.nongnu.org/libunwind/"
  url "https://github.com/libunwind/libunwind/releases/download/v1.8.3/libunwind-1.8.3.tar.gz"
  sha256 "be30d910e67f58d82e753231f1357f326a1a088acf126b21ff77e60aab19b90b"
  license "MIT"
  revision 1
  compatibility_version 1

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "701baff4411aede21fea67053bf52ab3308d64360b4e005ba06ddd9083335ac0"
  end

  keg_only "it conflicts with LLVM"

  depends_on :linux
  depends_on "xz"
  depends_on "zlib-ng-compat"

  def install
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <libunwind.h>
      int main() {
        unw_context_t uc;
        unw_getcontext(&uc);
        return 0;
      }
    C
    system ENV.cc, "-I#{include}", "test.c", "-L#{lib}", "-lunwind", "-o", "test"
    system "./test"
  end
end
