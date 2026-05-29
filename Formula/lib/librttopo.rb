class Librttopo < Formula
  desc "RT Topology Library"
  homepage "https://git.osgeo.org/gitea/rttopo/librttopo"
  url "https://deb.debian.org/debian/pool/main/libr/librttopo/librttopo_1.1.0.orig.tar.gz"
  sha256 "2e2fcabb48193a712a6c76ac9a9be2a53f82e32f91a2bc834d9f1b4fa9cd879f"
  license "GPL-2.0-or-later"
  compatibility_version 1
  head "https://git.osgeo.org/gitea/rttopo/librttopo.git", branch: "master"

  livecheck do
    url :head
    regex(/^(?:librttopo[._-])?v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c71cc3f2b4a37c7127007706e5c0f118509a32ed9772f4a0b7437d6a9d816b0f"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "geos"

  def install
    system "./autogen.sh"
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <librttopo.h>

      int main(int argc, char *argv[]) {
        printf("%s", rtgeom_version());
        return 0;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lrttopo", "-o", "test"
    assert_equal stable.version.to_s, shell_output("./test")
  end
end
