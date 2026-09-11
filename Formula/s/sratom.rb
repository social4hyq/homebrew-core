class Sratom < Formula
  desc "Library for serializing LV2 atoms to/from RDF"
  homepage "https://drobilla.net/software/sratom.html"
  url "https://download.drobilla.net/sratom-0.6.22.tar.xz"
  sha256 "0209b7d0f22c96abb416722ed735b0933be47931ecff4aa4b26ded7760b4f252"
  license "ISC"
  revision 1

  livecheck do
    url "https://download.drobilla.net"
    regex(/href=.*?sratom[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "117128cbc81b43840f6efac7f41f395a8f33aed3d6b590aec33e2952c6c432be"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on "lv2"
  depends_on "serd"
  depends_on "sord"

  def install
    system "meson", "setup", "build", "-Dtests=disabled", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <sratom/sratom.h>

      int main()
      {
        return 0;
      }
    C

    pkg_config_cflags = shell_output("pkg-config --cflags --libs sratom-0").chomp.split
    system ENV.cc, "test.c", *pkg_config_cflags, "-o", "test"
    system "./test"
  end
end
