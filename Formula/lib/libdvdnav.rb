class Libdvdnav < Formula
  desc "DVD navigation library"
  homepage "https://www.videolan.org/developers/libdvdnav.html"
  url "https://download.videolan.org/pub/videolan/libdvdnav/7.0.0/libdvdnav-7.0.0.tar.xz"
  sha256 "a2a18f5ad36d133c74bf9106b6445806fa253b09141a46392550394b647b221e"
  license "GPL-2.0-or-later"
  head "https://code.videolan.org/videolan/libdvdnav.git", branch: "master"

  livecheck do
    url "https://download.videolan.org/pub/videolan/libdvdnav/"
    regex(%r{href=["']?v?(\d+(?:\.\d+)+)/?["' >]}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f97da924d3d44f35af6f6197d026bd246fe3069cc8030279ccc769fd3934bc6e"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on "libdvdread"

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <dvdnav/version.h>
      #include <stdio.h>

      int main(int argc, char** argv) {
        printf("%s\\n", DVDNAV_VERSION_STRING);
        return 0;
      }
    C

    pkg_config_flags = shell_output("pkgconf --cflags --libs dvdnav").chomp.split
    system ENV.cc, "test.c", *pkg_config_flags, "-o", "test"
    assert_match version.to_s, shell_output("./test")
  end
end
