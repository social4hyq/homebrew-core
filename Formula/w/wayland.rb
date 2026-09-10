class Wayland < Formula
  desc "Protocol for a compositor to talk to its clients"
  homepage "https://wayland.freedesktop.org"
  url "http://ftp.debian.org/debian/pool/main/w/wayland/wayland_1.26.0.orig.tar.xz"
  sha256 "64176eaa46e4969903e286f8e5ef8331affc17fdf03ac9b58381d2b23162b7a3"
  license "MIT"
  revision 1
  compatibility_version 1

  # Versions with a 90+ patch are unstable (e.g., 1.21.91 is an alpha release)
  # and this regex should only match the stable versions.
  livecheck do
    url "https://wayland.freedesktop.org/releases.html"
    regex(/href=.*?wayland[._-]v?(\d+\.\d+(?:\.(?:\d|[1-8]\d+)(?:\.\d+)*)?)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "690fed8c618ac641523de013f0c63932585ae3abdfd3c9eece0b2458779cf676"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "expat"
  depends_on "libffi"
  depends_on "libxml2"
  depends_on :linux

  def install
    system "meson", "setup", "build", "-Dtests=false", "-Ddocumentation=false", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include "wayland-server.h"
      #include "wayland-client.h"

      int main(int argc, char* argv[]) {
        const char *socket;
        struct wl_protocol_logger *logger;
        return 0;
      }
    C
    system ENV.cc, "test.c", "-o", "test", "-I#{include}"
    system "./test"
  end
end
