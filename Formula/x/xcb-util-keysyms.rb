class XcbUtilKeysyms < Formula
  desc "Standard X constants and conversion to/from keycodes"
  homepage "https://xcb.freedesktop.org"
  url "https://xcb.freedesktop.org/dist/xcb-util-keysyms-0.4.1.tar.gz"
  sha256 "1fa21c0cea3060caee7612b6577c1730da470b88cbdf846fa4e3e0ff78948e54"
  license "X11"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7e59828a9eed4eefbfb57fa67340686c9a6e0632c76f7a363d034343c2101c50"
  end

  head do
    url "https://gitlab.freedesktop.org/xorg/lib/libxcb-keysyms.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkgconf" => [:build, :test]
  depends_on "libxcb"

  def install
    system "./autogen.sh" if build.head?
    system "./configure", "--disable-silent-rules",
                          "--localstatedir=#{var}",
                          "--sysconfdir=#{etc}",
                          *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    assert_match "-I#{include}", shell_output("pkg-config --cflags xcb-keysyms")
  end
end
