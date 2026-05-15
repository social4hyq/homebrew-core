class Libvterm < Formula
  desc "C99 library which implements a VT220 or xterm terminal emulator"
  homepage "https://www.leonerd.org.uk/code/libvterm/"
  url "https://launchpad.net/libvterm/trunk/v0.3/+download/libvterm-0.3.3.tar.gz"
  sha256 "09156f43dd2128bd347cbeebe50d9a571d32c64e0cf18d211197946aff7226e0"
  license "MIT"
  version_scheme 1

  livecheck do
    url :stable
    regex(/href=.*?libvterm[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6ffbab8826f4ec361f3ac171e8da4066d043efe65a8aad4256c81ac5d6639fa3"
  end

  depends_on "libtool" => :build

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <vterm.h>

      int main() {
        vterm_free(vterm_new(1, 1));
      }
    C

    system ENV.cc, "test.c", "-L#{lib}", "-lvterm", "-o", "test"
    system "./test"
  end
end
