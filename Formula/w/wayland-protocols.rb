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
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bc7903a57cddf9d09cb1e24a716ab34e9607d0dd697b8eb238ece269dc73629b"
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
