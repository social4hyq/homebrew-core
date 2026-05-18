class Libvdpau < Formula
  desc "Open source Video Decode and Presentation API library"
  homepage "https://www.freedesktop.org/wiki/Software/VDPAU/"
  url "https://ftp.debian.org/debian/pool/main/libv/libvdpau/libvdpau_1.5.orig.tar.bz2"
  sha256 "a5d50a42b8c288febc07151ab643ac8de06a18446965c7241f89b4e810821913"
  license "MIT"

  livecheck do
    url :stable
    regex(/^(?:libvdpau[._-])?v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e40a3a6d6244a58b2fb500249ed38991242d9c28557a17938ae559b0fea9ff4c"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on "libx11"
  depends_on "libxext"
  depends_on "xorgproto"

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end
  test do
    assert_match "-I#{include}", shell_output("pkgconf --cflags vdpau")
  end
end
