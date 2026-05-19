class Libxpresent < Formula
  desc "Xlib-based library for the X Present Extension"
  homepage "https://gitlab.freedesktop.org/xorg/lib/libxpresent"
  url "https://www.x.org/archive/individual/lib/libXpresent-1.0.2.tar.xz"
  sha256 "4e5b21b4812206a4b223013606ae31170502c1043038777a1ef8f70c09d37602"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2d0ff7816baa5c92e77ccb4a3c1af5aff98dae763dd71585b0218fd741433997"
  end

  head do
    url "https://gitlab.freedesktop.org/xorg/lib/libxpresent.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
    depends_on "util-macros" => :build
  end

  depends_on "pkgconf" => [:build, :test]
  depends_on "libx11"
  depends_on "libxext"
  depends_on "libxfixes"
  depends_on "libxrandr"

  def install
    configure = build.head? ? "./autogen.sh" : "./configure"
    system configure, "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <X11/extensions/Xpresent.h>

      int main() {
        XPresentNotify notify;
        return 0;
      }
    C
    system ENV.cc, "test.c"
    assert_equal 0, $CHILD_STATUS.exitstatus
  end
end
