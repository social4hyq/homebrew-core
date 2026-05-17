class Libmypaint < Formula
  desc "MyPaint brush engine library"
  homepage "https://github.com/mypaint/libmypaint/wiki"
  url "https://github.com/mypaint/libmypaint/releases/download/v1.6.1/libmypaint-1.6.1.tar.xz"
  sha256 "741754f293f6b7668f941506da07cd7725629a793108bb31633fb6c3eae5315f"
  license "ISC"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8996a2b9b4f285da0001f3e584b6339f20c25ab4f9e76d24465e8b837558679a"
  end

  depends_on "gettext" => :build # for intltool
  depends_on "intltool" => :build
  depends_on "pkgconf" => :build
  depends_on "json-c"

  uses_from_macos "perl" => :build

  on_macos do
    depends_on "gettext"
  end

  on_linux do
    depends_on "perl-xml-parser" => :build
  end

  def install
    system "./configure", "--disable-introspection",
                          "--without-glib",
                          *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <mypaint-brush.h>
      int main() {
        MyPaintBrush *brush = mypaint_brush_new();
        mypaint_brush_unref(brush);
        return 0;
      }
    C

    system ENV.cc, "test.c", "-I#{include}/libmypaint", "-L#{lib}", "-lmypaint", "-o", "test"
    system "./test"
  end
end
