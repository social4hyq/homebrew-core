class Libdvdcss < Formula
  desc "Access DVDs as block devices without the decryption"
  homepage "https://www.videolan.org/developers/libdvdcss.html"
  url "https://download.videolan.org/pub/videolan/libdvdcss/1.5.0/libdvdcss-1.5.0.tar.xz"
  sha256 "529463e4d1befef82e5c6e470db7661a2db0343e092a2fb0d6c037cab8a5c399"
  license "GPL-2.0-or-later"
  head "https://code.videolan.org/videolan/libdvdcss.git", branch: "master"

  livecheck do
    url "https://download.videolan.org/pub/libdvdcss/"
    regex(%r{href=["']?v?(\d+(?:\.\d+)+)/?["' >]}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6111059e86978ad3da3788e4f37bb510a4fd98a0fcec71128ec9ca8cc9cc0799"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :test

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <dvdcss/version.h>
      #include <stdio.h>

      int main(int argc, char** argv) {
        printf("%s\\n", DVDCSS_VERSION_STRING);
        return 0;
      }
    C

    pkg_config_flags = shell_output("pkgconf --cflags --libs libdvdcss").chomp.split
    system ENV.cc, "test.c", *pkg_config_flags, "-o", "test"
    assert_match version.to_s, shell_output("./test")
  end
end
