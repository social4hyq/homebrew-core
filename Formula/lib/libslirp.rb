class Libslirp < Formula
  desc "General purpose TCP-IP emulator"
  homepage "https://gitlab.freedesktop.org/slirp/libslirp"
  url "http://ftp.debian.org/debian/pool/main/libs/libslirp/libslirp_4.9.1.orig.tar.bz2"
  sha256 "3caff6e2de445f4995629d4929c55419f661b2b1d14f12481e155a71c1e8f811"
  license "BSD-3-Clause"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c7ba6d236cf09522f3faa47363c8dfb2c14adb4962f028bedd8c8ee2399b5a8c"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "glib"

  def install
    system "meson", "setup", "build", "-Ddefault_library=both", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <string.h>
      #include <stddef.h>
      #include <slirp/libslirp.h>
      int main() {
        SlirpConfig cfg;
        memset(&cfg, 0, sizeof(cfg));
        cfg.version = 1;
        cfg.in_enabled = true;
        cfg.vhostname = "testServer";
        Slirp* ctx = slirp_new(&cfg, NULL, NULL);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lslirp", "-o", "test"
    system "./test"
  end
end
