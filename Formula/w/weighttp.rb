class Weighttp < Formula
  desc "Webserver benchmarking tool that supports multithreading"
  homepage "https://redmine.lighttpd.net/projects/weighttp/wiki"
  url "https://github.com/lighttpd/weighttp/archive/refs/tags/weighttp-0.5.tar.gz"
  sha256 "5900600cc108041d0e38abd02354d7d3b14649c827c4266c0d550b87904f1141"
  license "MIT"
  head "https://git.lighttpd.net/lighttpd/weighttp.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dcd951fe3996e2984441248314291a4a28ce456640136952bba72f8a7968f965"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "libev"

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    # Stick with HTTP to avoid 'error: no ssl support yet'
    system bin/"weighttp", "-n", "1", "http://redmine.lighttpd.net/projects/weighttp/wiki"
  end
end
