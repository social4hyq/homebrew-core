class Lilv < Formula
  desc "C library to use LV2 plugins"
  homepage "https://drobilla.net/software/lilv.html"
  url "https://download.drobilla.net/lilv-0.28.0.tar.xz"
  sha256 "8dcb70adb5cf072335115a6b091f4113710bdc73abaadaa3f9e9c1e55957b149"
  license "ISC"
  revision 1

  livecheck do
    url "https://download.drobilla.net/"
    regex(/href=.*?lilv[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d3bda13dfcb8c82dbe72f0cb32b4dc758419435d0309314dfd6da1f916fe631a"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "python@3.14" => [:build, :test]
  depends_on "libsndfile"
  depends_on "lv2"
  depends_on "serd"
  depends_on "sord"
  depends_on "sratom"
  depends_on "zix"

  def python3
    "python3.14"
  end

  def install
    # FIXME: Meson tries to install into `prefix/HOMEBREW_PREFIX/lib/pythonX.Y/site-packages`
    #        without setting `python.*libdir`.
    prefix_site_packages = prefix/Language::Python.site_packages(python3)
    system "meson", "setup", "build", "-Dtests=disabled",
                                      "-Dbindings_py=enabled",
                                      "-Dtools=enabled",
                                      "-Dpython.platlibdir=#{prefix_site_packages}",
                                      "-Dpython.purelibdir=#{prefix_site_packages}",
                                      *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <lilv/lilv.h>

      int main(void) {
        LilvWorld* const world = lilv_world_new();
        lilv_world_free(world);
      }
    C
    system ENV.cc, "test.c", "-I#{include}/lilv-0", "-L#{lib}", "-llilv-0", "-o", "test"
    system "./test"

    system python3, "-c", "import lilv"
  end
end
