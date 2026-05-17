class Libmpd < Formula
  desc "Higher level access to MPD functions"
  homepage "https://gmpc.fandom.com/wiki/Gnome_Music_Player_Client"
  url "https://www.musicpd.org/download/libmpd/11.8.17/libmpd-11.8.17.tar.gz"
  sha256 "fe20326b0d10641f71c4673fae637bf9222a96e1712f71f170fca2fc34bf7a83"
  license "GPL-2.0-or-later"
  revision 1

  livecheck do
    url "https://www.musicpd.org/download/libmpd/"
    regex(%r{href=["']?v?(\d+(?:\.\d+)+)/?["' >]}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "15650898b8ed7754468a7ebe500b1a3b0db80b671d019173ef8fbdb2bae41430"
  end

  depends_on "pkgconf" => :build
  depends_on "gettext"
  depends_on "glib"

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-pre-0.4.2.418-big_sur.diff"
    sha256 "83af02f2aa2b746bb7225872cab29a253264be49db0ecebb12f841562d9a2923"
  end

  def install
    # Workaround for newer Clang
    ENV.append_to_cflags "-Wno-int-conversion" if DevelopmentTools.clang_build_version >= 1500

    ENV.append "CFLAGS", "-DHAVE_STRNDUP" unless OS.mac?

    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <stdlib.h>
      #include <libmpd/libmpd.h>

      int main() {
          MpdObj *mpd;
          char *hostname = "localhost";
          int port = 6600;

          mpd = mpd_new(hostname, port, NULL);
          printf("MPD object created");

          mpd_free(mpd);
          return 0;
      }
    C
    system ENV.cc, "test.c", "-o", "test", "-I#{include}/libmpd-1.0", "-L#{lib}", "-lmpd"
    system "./test"
  end
end
