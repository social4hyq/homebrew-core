class Robotfindskitten < Formula
  desc "Zen Simulation of robot finding kitten"
  homepage "http://robotfindskitten.org/"
  url "https://downloads.sourceforge.net/project/rfk/robotfindskitten-POSIX/ship_it_anyway/robotfindskitten-2.8284271.702.tar.gz"
  sha256 "020172e4f4630f7c4f62c03b6ffe2eeeba5637b60374d3e6952ae5816a9f99af"
  license "GPL-2.0-or-later"
  revision 1
  head "https://github.com/robotfindskitten/robotfindskitten.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ad223fff901d71abd36a09efc3f53fd42e62962505a1c397558c5edb0a591b0a"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  uses_from_macos "ncurses"

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", *std_configure_args
    system "make", "install", "execgamesdir=#{bin}"
  end

  test do
    assert_equal "robotfindskitten: #{version}",
      shell_output("#{bin}/robotfindskitten -V").chomp
  end
end
