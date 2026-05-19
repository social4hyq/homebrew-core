class XcbUtilRenderutil < Formula
  desc "Convenience functions for the X Render extension"
  homepage "https://xcb.freedesktop.org"
  url "https://xcb.freedesktop.org/dist/xcb-util-renderutil-0.3.10.tar.gz"
  sha256 "e04143c48e1644c5e074243fa293d88f99005b3c50d1d54358954404e635128a"
  license all_of: ["X11", "HPND-sell-variant"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c9f7182ff4fed035917f4bfab1d32152cbcea0525179fa12b0fdd10def6c827b"
  end

  head do
    url "https://gitlab.freedesktop.org/xorg/lib/libxcb-render-util.git", branch: "master"

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
    assert_match "-I#{include}", shell_output("pkg-config --cflags xcb-renderutil")
  end
end
