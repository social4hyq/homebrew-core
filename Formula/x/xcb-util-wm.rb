class XcbUtilWm < Formula
  desc "Client and window-manager helpers for EWMH and ICCCM"
  homepage "https://xcb.freedesktop.org"
  url "https://xcb.freedesktop.org/dist/xcb-util-wm-0.4.2.tar.gz"
  sha256 "dcecaaa535802fd57c84cceeff50c64efe7f2326bf752e16d2b77945649c8cd7"
  license "X11"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5faae0931b01c9d0bd5eb6ef48c8d1ed3fe3e6f0887ee84403a8791cab9e909d"
  end

  head do
    url "https://gitlab.freedesktop.org/xorg/lib/libxcb-wm.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkgconf" => [:build, :test]
  depends_on "libxcb"

  uses_from_macos "m4" => :build

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
    assert_match "-I#{include}", shell_output("pkg-config --cflags xcb-ewmh")
    assert_match "-I#{include}", shell_output("pkg-config --cflags xcb-icccm")
  end
end
