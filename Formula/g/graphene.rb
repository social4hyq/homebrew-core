class Graphene < Formula
  desc "Thin layer of graphic data types"
  homepage "https://ebassi.github.io/graphene/"
  url "https://github.com/ebassi/graphene/archive/refs/tags/1.10.8.tar.gz"
  sha256 "922dc109d2dc5dc56617a29bd716c79dd84db31721a8493a13a5f79109a4a4ed"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a749166532bf36cf0f43f8c18da972e7403f2518b353f2d6c996fd0288ca6d80"
  end

  depends_on "gobject-introspection" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => [:build, :test]

  depends_on "glib"

  on_macos do
    depends_on "gettext"
  end

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <graphene-gobject.h>

      int main(int argc, char *argv[]) {
      GType type = graphene_point_get_type();
        return 0;
      }
    C

    flags = shell_output("pkgconf --cflags --libs glib-2.0 graphene-1.0").chomp.split
    system ENV.cc, "test.c", *flags, "-o", "test"
  end
end
