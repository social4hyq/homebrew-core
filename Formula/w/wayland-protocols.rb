class WaylandProtocols < Formula
  desc "Additional Wayland protocols"
  homepage "https://wayland.freedesktop.org"
  url "http://ftp.debian.org/debian/pool/main/w/wayland-protocols/wayland-protocols_1.49.orig.tar.xz"
  sha256 "ec4c8f74942d6dff7ace8b4ce4764f0ef9ff618a935d974ea77edee2ad240b14"
  license "MIT"
  revision 1
  compatibility_version 1

  livecheck do
    url "https://wayland.freedesktop.org/releases.html"
    regex(/href=.*?wayland-protocols[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "61bd781d315fae42019535ed31e74753b6e779b336d1373fe1f8e1359b0f3e17"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on :linux
  depends_on "wayland"

  def install
    system "meson", "setup", "build", "-Dtests=false", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    system "pkg-config", "--exists", "wayland-protocols"
    assert_equal 0, $CHILD_STATUS.exitstatus
  end
end
