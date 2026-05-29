class XcbUtilImage < Formula
  desc "XCB port of Xlib's XImage and XShmImage"
  homepage "https://xcb.freedesktop.org"
  url "https://xcb.freedesktop.org/dist/xcb-util-image-0.4.1.tar.gz"
  sha256 "0ebd4cf809043fdeb4f980d58cdcf2b527035018924f8c14da76d1c81001293b"
  license "X11"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2011b1386ffccd44eb120b49c88ca2a5e7adb0324832f7d557e7fb0a72ffcea0"
  end

  head do
    url "https://gitlab.freedesktop.org/xorg/lib/libxcb-image.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkgconf" => [:build, :test]
  depends_on "libxcb"
  depends_on "xcb-util"

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
    assert_match "-I#{include}", shell_output("pkg-config --cflags xcb-image")
  end
end
