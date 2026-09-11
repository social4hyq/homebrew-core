class Libpciaccess < Formula
  desc "Generic PCI access library"
  homepage "https://www.x.org/"
  url "https://www.x.org/pub/individual/lib/libpciaccess-0.19.tar.xz"
  sha256 "3c55aa86c82e54a4e3109786f0463530d53b36b6d1cfd14616454f985dd2aa43"
  license "MIT"
  revision 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4ad157994bf7da2c646cb3fcee0b0b26b90d38779402e6cc89e85a8f537ed6e8"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "util-macros" => :build
  depends_on :linux
  depends_on "zlib-ng-compat"

  def install
    # Work around Meson's automatic removal of RPATHs by explicitly passing in LDFLAGS
    ENV.append "LDFLAGS", "-Wl,-rpath,#{Formula["zlib-ng-compat"].opt_lib}"

    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include "pciaccess.h"
      int main(int argc, char* argv[]) {
        int pci_system_init(void);
        const struct pci_id_match *match;
        struct pci_device_iterator *iter;
        struct pci_device *dev;
        return 0;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lpciaccess"
  end
end
