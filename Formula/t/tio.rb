class Tio < Formula
  desc "Simple TTY terminal I/O application"
  homepage "https://tio.github.io"
  url "https://github.com/tio/tio/releases/download/v3.9/tio-3.9.tar.xz"
  sha256 "06fe0c22e3e75274643c017928fbc85e86589bc1acd515d92f98eecd4bbab11b"
  license "GPL-2.0-or-later"
  revision 1
  head "https://github.com/tio/tio.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5e06af58d9c6f7e40dd073e117ca13dbe0e6425e7385cde1ffdcda5b291e4dd8"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build

  depends_on "glib"
  depends_on "lua"

  def install
    system "meson", "setup", "build", "-Dbashcompletiondir=#{bash_completion}", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    assert_match "Error: Not a tty device", shell_output("#{bin}/tio /dev/null 2>&1", 1)
  end
end
