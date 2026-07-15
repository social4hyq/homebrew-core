class Libdvdread < Formula
  desc "C library for reading DVD-video images"
  homepage "https://www.videolan.org/developers/libdvdnav.html"
  url "https://download.videolan.org/pub/videolan/libdvdread/7.1.0/libdvdread-7.1.0.tar.xz"
  sha256 "0bab58b7fbbc22a4a8497435eda7c88c20ba5b575da22d1ee2c6842c16dae8ea"
  license "GPL-2.0-or-later"
  compatibility_version 1
  head "https://code.videolan.org/videolan/libdvdread.git", branch: "master"

  livecheck do
    url "https://download.videolan.org/pub/videolan/libdvdread/"
    regex(%r{href=["']?v?(\d+(?:\.\d+)+)/?["' >]}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ad55931dc1cfa528c278f210f35d47fa9162519b6561e70ec6d13188756d9d7f"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on "libdvdcss"

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <dvdread/version.h>
      #include <stdio.h>

      int main(int argc, char** argv) {
        printf("%s\\n", DVDREAD_VERSION_STRING);
        return 0;
      }
    C

    pkg_config_flags = shell_output("pkgconf --cflags --libs dvdread").chomp.split
    system ENV.cc, "test.c", *pkg_config_flags, "-o", "test"
    assert_match version.to_s, shell_output("./test")
  end
end
