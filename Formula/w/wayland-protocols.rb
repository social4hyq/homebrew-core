class WaylandProtocols < Formula
  desc "Additional Wayland protocols"
  homepage "https://wayland.freedesktop.org"
  url "http://ftp.debian.org/debian/pool/main/w/wayland-protocols/wayland-protocols_1.48.orig.tar.xz"
  sha256 "398036ac0eb6484982ddbde7ff86848d753231f9cdeeae983f06b52946625aa1"
  license "MIT"
  compatibility_version 1

  livecheck do
    url "https://wayland.freedesktop.org/releases.html"
    regex(/href=.*?wayland-protocols[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, all: "68739c4ed022227790daf4787fea9ca96ab691586140d28baab07e7ea18cbe4a"
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
