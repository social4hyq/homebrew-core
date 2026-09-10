class Xclip < Formula
  desc "Access X11 clipboards from the command-line"
  homepage "https://github.com/astrand/xclip"
  url "https://github.com/astrand/xclip/archive/refs/tags/0.13.tar.gz"
  sha256 "ca5b8804e3c910a66423a882d79bf3c9450b875ac8528791fb60ec9de667f758"
  license "GPL-2.0-or-later"
  revision 2

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b8f8bea85cabceea57d0786dbdb242938965adfd68c23ed030c252907f03a09d"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libx11"
  depends_on "libxmu"

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"xclip", "-version"
  end
end
