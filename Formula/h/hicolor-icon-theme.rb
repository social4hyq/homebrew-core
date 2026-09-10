class HicolorIconTheme < Formula
  desc "Fallback theme for FreeDesktop.org icon themes"
  homepage "https://wiki.freedesktop.org/www/Software/icon-theme/"
  url "https://icon-theme.freedesktop.org/releases/hicolor-icon-theme-0.18.tar.xz"
  sha256 "db0e50a80aa3bf64bb45cbca5cf9f75efd9348cf2ac690b907435238c3cf81d7"
  license "GPL-2.0-only"
  revision 1
  head "https://gitlab.freedesktop.org/xdg/default-icon-theme.git", branch: "master"

  # The homepage hasn't been updated to link to more recent versions, so we
  # have to check the directory listing page instead.
  livecheck do
    url "https://icon-theme.freedesktop.org/releases/"
    regex(/href=.*?hicolor-icon-theme[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6025e9ada767e88ab5e3ff4b5e75360f2481d948477880d0cd0196f94bac98c0"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    assert_path_exists share/"icons/hicolor/index.theme"
  end
end
