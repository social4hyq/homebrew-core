class XkeyboardConfig < Formula
  desc "Keyboard configuration database for the X Window System"
  homepage "https://www.freedesktop.org/wiki/Software/XKeyboardConfig/"
  url "https://xorg.freedesktop.org/archive/individual/data/xkeyboard-config/xkeyboard-config-2.47.tar.xz"
  sha256 "e59984416a72d58b46a52bfec1b1361aa7d84354628227ee2783626c7a6db6b6"
  license "MIT"
  compatibility_version 1
  head "https://gitlab.freedesktop.org/xkeyboard-config/xkeyboard-config.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cf976f4127db8770a54d3e1d5e6adaab5dde46fcfdbde675864f02d770c7c045"
  end

  depends_on "gettext" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on "python@3.14" => :build

  uses_from_macos "libxslt" => :build

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    assert_path_exists man7/"xkeyboard-config.7"
    assert_equal "#{share}/X11/xkb", shell_output("pkg-config --variable=xkb_base xkeyboard-config").chomp
    assert_match "Language-Team: English",
      shell_output("strings #{share}/locale/en_GB/LC_MESSAGES/xkeyboard-config.mo")
  end
end
